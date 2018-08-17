# frozen_string_literal: true

module PostConcerns::Autoflagging
  extend ActiveSupport::Concern

  included do
    scope(:autoflagged, -> { where(autoflagged: true) })
    scope(:not_autoflagged, -> { where(autoflagged: false) })

    def autoflag
      Rails.logger.warn "[autoflagging] #{id}: Post#autoflag begin"
      return 'Duplicate post' unless Post.where(link: link).count == 1
      return 'Flagging disabled' unless FlagSetting['flagging_enabled'] == '1'
      Rails.logger.warn "[autoflagging] #{id}: not a dupe"

      dry_run = FlagSetting['dry_run'] == '1'
      post = self

      begin
        conditions = post.site.flag_conditions.where(flags_enabled: true)
        available_user_ids = {}
        conditions.each do |condition|
          if condition.validate!(post)
            available_user_ids[condition.user.id] = condition
          end
        end
        Rails.logger.warn "[autoflagging] #{id}: fetched conditions"

        uids = post.site.user_site_settings.where(user_id: available_user_ids.keys).map(&:user_id)
        users = User.where(id: uids, flags_enabled: true).where.not(encrypted_api_token: nil)
        if users.blank?
          Rails.logger.warn "[autoflagging] #{id}: no users available"
          post.send_not_autoflagged
          return 'No users eligible to flag'
        end

        Rails.logger.warn "[autoflagging] #{id}: before revision count"
        post.fetch_revision_count
        unless post.revision_count == 1
          Rails.logger.warn "[autoflagging] #{id}: vandalized"
          post.send_not_autoflagged
          return 'More than one revision'
        end

        Rails.logger.warn "[autoflagging] #{id}: lottery begin"

        # Defined by the scaled_max_flags FlagSetting
        # scaled_max_flags = 0,0,0,99.9,99.99,101 would always allow 3 flags,
        # 4 flags on 99.9% accuracy, and 5 flags on 99.99% accuracy.
        # 101% means six flags is never allowed
        scaled_maxes = FlagSetting['scaled_max_flags']&.split(',')
        Rails.logger.warn "[autoflagging] #{id}: scaled maxes: #{scaled_maxes}"
        if !scaled_maxes.nil? && scaled_maxes.count == 6
          # Check historical accuracy
          fake_flag_condition = FlagCondition.new(
            sites: Site.mains,
            max_poster_rep: post.user_reputation,
            min_reason_count: 1,
            min_weight: post.reasons.sum(&:weight)
          )

          accuracy = fake_flag_condition.accuracy # Decimal number, like 99.8

          # If the accuracy is higher than all 6 thresholds (indicating 6 flags), index will be null
          scaled_max = scaled_maxes.index { |n| n.to_f > accuracy } || FlagSetting['max_flags'].to_i
        else
          scaled_max = FlagSetting['max_flags'].to_i
        end

        max_flags = [post.site.max_flags_per_post, (FlagSetting['max_flags'] || '3').to_i, scaled_max].min

        # Send the first flag with Smokey's account; shows up nicely in the flag queue / timeline
        # At this stage, we know that at least one user has a matching flag_condition (thus 99.x% accuracy)

        max_flags -= post.send_autoflag(User.smokey, dry_run, nil) unless User.smokey.nil?

        core_count = (max_flags / 2.0).ceil
        other_count = max_flags - core_count

        core_users_used = []
        Rails.logger.warn "[autoflagging] #{id}: core..."
        users.with_role(:core).shuffle.each do |user|
          break if core_count <= 0
          core_count -= post.send_autoflag(user, dry_run, available_user_ids[user.id])
          core_users_used << user
        end

        Rails.logger.warn "[autoflagging] #{id}: plebs..."
        # Go through all non-core users first; then add core users at the end. See #146
        ((users.without_role(:core).shuffle + users.with_role(:core).shuffle) - core_users_used).each do |user|
          break if other_count <= 0
          other_count -= post.send_autoflag(user, dry_run, available_user_ids[user.id])
        end
      rescue => e
        Rails.logger.warn "[autoflagging] #{id}: exception #{e} :("
        FlagLog.create(success: false, error_message: "#{e}: #{e.message} | #{e.backtrace.join("\n")}",
                       is_dry_run: dry_run, flag_condition: nil, post: post,
                       site_id: post.site_id)

        # Re-raise if we're in test, 'cause it shouldn't be throwing in test
        raise if Rails.env.test?
      end

      if post.flag_logs.where(success: true).empty?
        post.send_not_autoflagged
      else
        post.update_columns(autoflagged: true)
      end
    end

    def send_autoflag(user, dry_run, condition)
      Rails.logger.warn "[autoflagging] #{id}: send_autoflag begin: #{user.username}"
      user_site_flag_count = user.flag_logs.where(site: site, success: true, is_dry_run: false).where(created_at: Date.today..Time.now).count
      return 0 if user_site_flag_count >= (user.user_site_settings.includes(:sites).where(sites: { id: site.id }).minimum(:max_flags) || -1)
      Rails.logger.warn "[autoflagging] #{id}: has enough flags"
      last_log = FlagLog.auto.where(user: user).last
      if last_log.try(:backoff).present? && (last_log.created_at + last_log.backoff.seconds > Time.now)
        Rails.logger.warn "[autoflagging] #{id}: flag settings backoff..."
        sleep((last_log.created_at + last_log.backoff.seconds) - Time.now)
      end

      Rails.logger.warn "[autoflagging] #{id}: pre spam_flag"
      success, message = user.spam_flag(self, dry_run)
      Rails.logger.warn "[autoflagging] #{id}: post spam_flag"
      backoff = 0
      backoff = message if success

      unless [
        'Flag options not present',
        'Flag option not present',
        'You do not have permission to flag this post',
        'No account on this site.',
        'User is a moderator on this site'
      ].include? message
        flag_log = FlagLog.create(success: success, error_message: message,
                                  is_dry_run: dry_run, flag_condition: condition,
                                  user: user, post: self, backoff: backoff,
                                  site_id: site_id)

        if success
          Rails.logger.warn "[autoflagging] #{id}: send_autoflagged..."
          log_as_json = JSON.parse(FlagLogController.render(locals: { flag_log: flag_log }, partial: 'flag_log.json'))
          ActionCable.server.broadcast 'api_flag_logs', flag_log: log_as_json
          ActionCable.server.broadcast 'flag_logs', row: FlagLogController.render(locals: { log: flag_log }, partial: 'flag_log')
          Rails.logger.warn "[autoflagging] #{id}: broadcast"
        end
      end

      success ? 1 : 0
    end

    def send_not_autoflagged
      Rails.logger.warn "[autoflagging] #{id}: send_not_autoflagged..."
      ActionCable.server.broadcast 'api_flag_logs', not_flagged: {
        post_link: link,
        post: JSON.parse(PostsController.render(locals: { post: self }, partial: 'post.json'))
      }
      Rails.logger.warn "[autoflagging] #{id}: broadcast"
    end

    def eligible_flaggers
      conditions = site.flag_conditions.where(flags_enabled: true)
      available_user_ids = {}
      conditions.each do |condition|
        if condition.validate!(self)
          available_user_ids[condition.user_id] = condition
        end
      end

      uids = site.user_site_settings.where(user_id: available_user_ids.keys).map(&:user_id)
      User.where(id: uids, flags_enabled: true).where.not(encrypted_api_token: nil)
    end

    def flagged?
      if flag_logs.loaded?
        flag_logs.select { |f| f.success && f.is_auto }.present?
      else
        flag_logs.where(success: true, is_auto: true).present?
      end
    end

    def flaggers
      User.joins(:flag_logs).where(flag_logs: { success: true, post_id: id, is_auto: true })
    end

    def manual_flaggers
      User.joins(:flag_logs).where(flag_logs: { success: true, post_id: id, is_auto: false })
    end

    def fetch_revision_count(post = nil)
      Rails.logger.warn "[autoflagging] #{id}: fetch_revision_count begin"
      post ||= self
      return if post.site.blank?
      Rails.logger.warn "[autoflagging] #{id}: site was present"
      params = "key=#{AppConfig['stack_exchange']['key']}&site=#{post.site.site_domain}&filter=!mggE4ZSiE7"

      url = "https://api.stackexchange.com/2.2/posts/#{post.stack_id}/revisions?#{params}"
      revision_list = JSON.parse(Net::HTTP.get_response(URI.parse(url)).body)['items']
      Rails.logger.warn "[autoflagging] #{id}: queried SE: #{revision_list&.count}"

      update(revision_count: revision_list.count)
      revision_list.count
    end
  end
end
