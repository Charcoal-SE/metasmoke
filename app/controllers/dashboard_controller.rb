# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :verify_developer, only: [:db_dumps, :download_dump]

  def index
    @inactive_reasons, @active_reasons = [true, false].map do |inactive|
      Reason.all.joins(:posts)
            .where('reasons.inactive = ?', inactive)
            .group(Arel.sql('reasons.id'))
            .select('reasons.*, count(\'posts.*\') as post_count')
            .order(Arel.sql('post_count DESC'))
            .to_a
    end
    @reasons = Reason.all
    @posts = Post.all
  end

  def new_dash; end

  def spam_by_site
    @posts = Post.includes_for_post_row

    @posts = @posts.where(site_id: params[:site]) if params[:site].present?

    @posts = @posts.undeleted if params[:undeleted].present?

    @posts = @posts.order(id: :desc).paginate(per_page: 50, page: params[:page])
    @sites = Site.where(id: @posts.map(&:site_id))
  end

  def site_dash
    @posts = Post.includes_for_post_row.includes(:flag_logs)
    params[:site_id] = Site.first.id if params[:site_id].blank?
    @site = Site.find(params[:site_id])

    @months = params[:months].to_s.empty? ? 3 : params[:months].to_i
    @months_string = @months <= 1 ? 'month' : "#{@months} months"

    @all_posts = @posts.where(site_id: @site.id)

    @tabs = {
      'All' => @all_posts,
      'Autoflagged' => @all_posts.where(autoflagged: true),
      'Deleted' => @all_posts.where.not(deleted_at: nil),
      'Undeleted' => @all_posts.where(deleted_at: nil)
    }
    special_tabs = %w[Spammers Autoflaggers]
    @active_tab = (@tabs.keys + special_tabs).map(&:downcase).include?(params[:tab]&.downcase) ? params[:tab]&.downcase : 'all'

    @posts = @tabs.map { |k, v| [k.downcase, v] }.to_h[params[:tab]&.downcase] || @tabs['All']

    @flags = FlagLog.where(site: @site).where('`flag_logs`.`created_at` >= ?', @months.months.ago).auto

    @spammers = StackExchangeUser.joins(:feedbacks).where(site: @site, still_alive: true)
                                 .where("feedbacks.feedback_type LIKE 't%'").group('stack_exchange_users.id')
                                 .order(Arel.sql('stack_exchange_users.reputation DESC'))

    @spammers_page = @spammers.paginate(per_page: 50, page: params[:page])

    @autoflaggers = User.joins(:flag_logs, flag_logs: [:post])
                        .where(flag_logs: { site: @site, success: true, is_auto: true })
                        .group(Arel.sql('users.id'))
                        .order(Arel.sql('COUNT(DISTINCT flag_logs.id) DESC'))
                        .select(Arel.sql('users.stack_exchange_account_id, users.username, COUNT(DISTINCT flag_logs.id) AS total_flags,'\
                                         'COUNT(DISTINCT IF(posts.is_tp = 1, flag_logs.id, NULL)) AS tp_flags'))

    @autoflaggers_page = @autoflaggers.paginate(per_page: 50, page: params[:page])

    @posts = @posts.order(id: :desc).paginate(per_page: 50, page: params[:page])
  end

  def db_dumps
    @dumps = Dir.chdir(Rails.root.join('dumps')) do
      Dir.glob '*.sql.gz'
    end
  end

  def download_dump
    valid = Dir.chdir(Rails.root.join('dumps')) do
      Dir.glob '*.sql.gz'
    end
    @dump = Rails.root.join('dumps', params[:filename])

    if !valid.include? params[:filename]
      render status: 401, layout: nil
    else
      send_file @dump, type: 'application/octet-stream'
    end
  end
end
