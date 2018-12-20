# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :verify_core, only: [:db_dumps, :download_dump]
  before_action :verify_developer, only: [:reset_query_time]

  def funride
    response.cache_control = 'public, max-age=86400'
    redirect_to 'https://speed.hetzner.de/10GB.bin', status: :moved_permanently
  end

  def index
    if params[:id].present?
      redirect_to '/magic/funride', status: :moved_permanently
      return
    end

    Rack::MiniProfiler.step('Redis queries') do
      @inactive_reasons, @active_reasons = #Rails.cache.fetch 'reasons_index', expires_in: 6.hours do
        [true, false].map do |inactive|
          results = Reason.where(inactive: inactive).to_a.map do |reason|
            reason.define_singleton_method(:post_count) { redis.scard "reasons/#{reason.id}" }
            reason
          end.sort_by(&:post_count).reverse
          counts = results.map do |reason|
            per_feedback_counts = %i[tp fp naa].map do |fb|
              redis.sinterstore "reasons/#{reason.id}/#{fb}s", "reasons/#{reason.id}", "#{fb}s"
              if fb == :tp
                redis.sdiffstore "reasons/#{reason.id}/tps", "reasons/#{reason.id}/tps", "reasons/#{reason.id}/fps", "reasons/#{reason.id}/naas"
              end
              if fb == :fp
                redis.sdiffstore "reasons/#{reason.id}/fps", "reasons/#{reason.id}/fps", "reasons/#{reason.id}/tps", "reasons/#{reason.id}/naas"
              end
              [fb, redis.scard("reasons/#{reason.id}/#{fb}s")]
            end.to_h

            [reason.id, {total: redis.scard("reasons/#{reason.id}")}.merge(per_feedback_counts)]
          end.to_h

          {counts: counts, results: results}
        end
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

  def query_times
    @query_times = params[:count].present? ? QueryAverage.all.order(counter: :desc) : QueryAverage.all.order(average: :desc)
  end

  def reset_query_time
    QueryAverage.find(params[:id]).update(counter: 0, average: 0)
    redirect_back fallback_location: root_path
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

    @spammers = StackExchangeUser.joins(:feedbacks).includes(:posts).where(site: @site, still_alive: true)
                                 .where("feedbacks.feedback_type LIKE 't%'").group('stack_exchange_users.id')
                                 .order('COUNT(posts.stack_exchange_user_id) DESC')
    # .order(Arel.sql('stack_exchange_users.reputation DESC'))

    @spammers_page = @spammers.paginate(per_page: 50, page: params[:page])

    @autoflaggers = User.joins(:flag_logs, flag_logs: [:post])
                        .where(flag_logs: { site: @site, success: true, is_auto: true })
                        .group(Arel.sql('users.id'))
                        .order(Arel.sql('COUNT(DISTINCT flag_logs.id) DESC'))
                        .select(Arel.sql('users.stack_exchange_account_id, users.username, COUNT(DISTINCT flag_logs.id) AS total_flags,'\
                                         'COUNT(DISTINCT IF(posts.is_tp = 1, flag_logs.id, NULL)) AS tp_flags'))

    @autoflaggers_page = @autoflaggers.paginate(per_page: 50, page: params[:page])

    @delimiter = "\u2005".encode('utf-8')

    @posts_timescaled = @posts.where('posts.created_at >= ?', @months.months.ago)
    @posts = @posts.order(id: :desc).paginate(per_page: 50, page: params[:page])
  end
end
