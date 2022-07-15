# frozen_string_literal: true

module PostConcerns::Autoflagging
  extend ActiveSupport::Concern

  included do
    scope(:autoflagged, -> { where(autoflagged: true) })
    scope(:not_autoflagged, -> { where(autoflagged: false) })

    def autoflag
      Rails.logger.warn "[autoflagging] #{id}: Post#autoflag begin"

      post = self
      begin
        Rails.logger.warn "[autoflagging] #{id}: before revision count"
        post.fetch_revision_count
        unless post.revision_count == 1
          Rails.logger.warn "[autoflagging] #{id}: vandalized"
          post.send_not_autoflagged
          return 'More than one revision'
        end

        return 'Duplicate post' unless Post.where(link: link).count == 1
        return 'Flagging disabled' unless FlagSetting['flagging_enabled'] == '1'
        Rails.logger.warn "[autoflagging] #{id}: not a dupe"

        dry_run = FlagSetting['dry_run'] == '1'

        conditions = post.site.flag_conditions.where(flags_enabled: true)
        available_user_ids = {}
        conditions.each do |condition|
          if condition.validate!(post)
            available_user_ids[condition.user.id] = condition
          end
        end
        Rails.logger.warn "[autoflagging] #{id}: fetched conditions (#{conditions.to_a.size}), #{available_user_ids.size} valid (available users)"

        uids = post.site.user_site_settings.where(user_id: available_user_ids.keys).map(&:user_id)
        users = User.where(id: uids, flags_enabled: true, write_authenticated: true)
        if users.blank?
          Rails.logger.warn "[autoflagging] #{id}: no users available (#{uids.size} uids, #{users.to_a.size} users)"
          post.send_not_autoflagged
          return 'No users eligible to flag'
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

          pre = DateTime.now
          Rails.logger.warn "[autoflagging] #{id}: check historical accuracy"
          accuracy = fake_flag_condition.accuracy # Decimal number, like 99.8
          post_ts = DateTime.now
          Rails.logger.warn "[autoflagging] #{id}: historical accuracy #{accuracy}, " \
                            "time taken #{((post_ts - pre) * 86_400).to_f} seconds"

          # If the accuracy is higher than all 6 thresholds (indicating 6 flags), index will be null
          scaled_max = scaled_maxes.index { |n| n.to_f > accuracy } || FlagSetting['max_flags'].to_i
        else
          scaled_max = FlagSetting['max_flags'].to_i
        end

        max_flags = [post.site.max_flags_per_post, (FlagSetting['max_flags'] || '3').to_i, scaled_max].min

        # Send the first flag with Smokey's account; shows up nicely in the flag queue / timeline
        # At this point, we know that at least one user has a matching flag_condition (thus 99.x% accuracy).
        # For all of the below, we're only considering users with matching flagging conditions and preferences.

        max_flags -= post.send_autoflag(User.smokey, dry_run, nil) unless User.smokey.nil?

        # The logic to select users for autoflags gives some priority to users with the Core
        # role.  The reason for this is that users with the Core role *tend* to be more
        # available to handle issues like getting FP feedback on an autoflagged post.  Core
        # users also look at it as a perk, even though it's really a responsibility.
        # For 2 flags, this will be 1 for SmokeDetector, 1 for Core users, and 0 for "non-Core" users.
        # For 3 flags, this will be 1 for SmokeDetector, 1 for Core users, and 1 for "non-Core" users.
        # For 4 flags, this will be 1 for SmokeDetector, 2 for Core users, and 1 for "non-Core" users.
        # For 5 flags, this will be 1 for SmokeDetector, 2 for Core users, and 2 for "non-Core" users.
        # For 6 flags, this will be 1 for SmokeDetector, 3 for Core users, and 2 for "non-Core" users.
        # In all of the above cases, "non-Core" means all users without the Core role and those users
        # with the Core role who were not selected for the flags allocated to Core users. How those
        # "non-Core" flags are allocated is determined below.
        core_count = (max_flags / 2.0).ceil
        other_count = max_flags - core_count
        core_users = users.with_role(:core)
        non_core_users = users.without_role(:core)
        core_users_per_flag = core_count == 0 ? 0 : core_users.length / core_count
        non_core_users_per_flag = other_count == 0 ? 0 : non_core_users.length / other_count

        core_users_used = []
        Rails.logger.warn "[autoflagging] #{id}: core..."
        core_users.shuffle.each do |user|
          break if core_count <= 0
          core_count -= post.send_autoflag(user, dry_run, available_user_ids[user.id])
          core_users_used << user
        end

        unused_core_users = core_users - core_users_used
        # It's possible here that there weren't enough core users to consume all of the core flags.
        # If so, that means that there are no unused_core_users, but that unused_core_users is empty
        # isn't something which we need to specifically handle.
        other_count += core_count

        # We don't want it to be more likely that a non-Core user with aggressive flagging
        # conditions will get flags than that the same user would get flags if they have the
        # Core role.  So, if there's more core_users per flag allocated to Core users than
        # there are non_core_users per flag allocated to non-Core users, then we share the
        # remaining flags equally between all remaining users.  If that conditions isn't
        # met, then we try the actual non-Core users first and then move on to any Core
        # users which have not already been attemped, should it not be possible to raise all
        # the desired flags with the actual non-Core users.
        remaining_users = if core_users_per_flag >= non_core_users_per_flag
                            # Equally share remaining flags between core and non-core users.
                            (non_core_users + unused_core_users).shuffle
                          else
                            # Give non-core users priority for the non-core flags.
                            # Go through all non-core users first; then add core users at the end. See #146
                            (non_core_users.shuffle + unused_core_users.shuffle)
                          end

        Rails.logger.warn "[autoflagging] #{id}: plebs..."
        remaining_users.each do |user|
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
          ActionCable.server.broadcast 'flag_logs', row: FlagLogController.render(locals: { log: flag_log, render_source: :controller },
                                                                                  partial: 'flag_log')
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
      User.where(id: uids, flags_enabled: true, write_authenticated: true)
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
      params = "key=#{AppConfig['stack_exchange']['key']}&site=#{post.site.site_domain}&filter=!mggkQI*4m9"

      url = "https://api.stackexchange.com/2.2/posts/#{post.stack_id}/revisions?#{params}"
      revision_list = JSON.parse(Net::HTTP.get_response(URI.parse(url)).body)['items']
      # Filter out items which are not actual post revisions
      revision_list = revision_list.select { |revision| revision['revision_number'].present? }
      Rails.logger.warn "[autoflagging] #{id}: queried SE: #{revision_list&.count}"

      update(revision_count: revision_list.count)
      revision_list.count
    end

    def spam_wave_autoflag
      Thread.new do
        Rails.logger.warn '[autoflagging-sw] spam wave check begin'

        waves = SpamWave.active.joins(:sites).where(sites: { id: site_id })
        if waves.any?
          Rails.logger.warn '[autoflagging-sw] active waves exist'
          waves.each do |w|
            next unless w.post_matches?(self)
            Rails.logger.warn '[autoflagging-sw] found matching wave'
            flag_count = autoflagged? ? w.max_flags - flag_logs.successful.auto.count : w.max_flags
            users = User.where(flags_enabled: true).shuffle
            users.each do |user|
              break if flag_count <= 0
              flag_count -= send_autoflag(user, nil, nil)
            end
          end
        else
          Rails.logger.warn '[autoflagging-sw] no waves'
        end

        Rails.logger.warn '[autoflagging-sw] spam wave check end'
      end
    end
  end
end
