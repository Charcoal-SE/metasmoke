# frozen_string_literal: true

class GraphsController < ApplicationController
  def index; end

  def reports_by_hour
    data = cached_query :reports_by_hour_graph do
      [
        { name: 'All', data: Post.group_by_hour(:created_at, range: 1.week.ago.to_date..Time.now).count },
        { name: 'True positives', data: Post.where(is_tp: true).group_by_hour(:created_at, range: 1.week.ago.to_date..Time.now).count },
        { name: 'False positives', data: Post.where(is_fp: true).group_by_hour(:created_at, range: 1.week.ago.to_date..Time.now).count }
      ]
    end
    render json: data
  end

  def reports_by_site
    @posts = if params[:timeframe] == 'all'
               Post.all
             else
               Post.where('created_at >= ?', 1.month.ago)
             end
    h = HTMLEntities.new

    render json: @posts.group(:site)
                       .count
                       .map { |k, v| { (k.nil? ? 'Unknown' : h.decode(k.site_name)) => v } }
                       .reduce(:merge)
                       .reject { |k, _v| k == 'Unknown' }
                       .sort_by { |_k, v| v }.reverse
  end

  def reports_by_hour_of_day
    @posts = if params[:timeframe] == 'all'
               Post.all
             else
               Post.where('created_at >= ?', 1.month.ago)
             end

    number_of_days = (DateTime.now - @posts.minimum(:created_at).to_date).to_i
    tp_posts = @posts.where(is_tp: true).group_by_hour_of_day(:created_at).count.map { |k, v| [k, (v.to_f / number_of_days).round(2)] }.to_h
    fp_posts = @posts.where(is_fp: true).group_by_hour_of_day(:created_at).count.map { |k, v| [k, (v.to_f / number_of_days).round(2)] }.to_h

    render json: [
      { name: 'All', data: @posts.group_by_hour_of_day(:created_at).count.map { |k, v| [k, (v.to_f / number_of_days).round(2)] }.to_h },
      { name: 'True positives', data: tp_posts },
      { name: 'False positives', data: fp_posts }
    ]
  end

  def time_to_deletion
    data = cached_query :time_to_deletion_graph, expires_in: 1.day, always_cache: true do
      Post.group_by_hour_of_day(:created_at).where(is_tp: true)
          .where('TIMESTAMPDIFF(SECOND, `posts`.`created_at`, `posts`.`deleted_at`) <= 3600')
          .where.not(deleted_at: nil)
          .average('TIMESTAMPDIFF(SECOND, `posts`.`created_at`, `posts`.`deleted_at`)')
    end
    render json: data
  end

  def flagging_results
    data = cached_query :flagging_results_graph do
      [
        ['Fail', FlagLog.auto.where(success: false).count],
        ['Dry run', FlagLog.auto.where(success: true, is_dry_run: true).count],
        ['Success', FlagLog.auto.where(success: true, is_dry_run: false).count]
      ]
    end
    render json: data
  end

  def flagging_timeline
    data = cached_query :flagging_timeline_graph do
      [
        {
          name: 'Failures',
          data: FlagLog.auto.where(success: false).group_by_day(:created_at, range: 1.month.ago.to_date..Time.now).count
        },
        {
          name: 'Dry runs',
          visible: false,
          data: FlagLog.auto.where(success: true, is_dry_run: true).group_by_day(:created_at, range: 1.month.ago.to_date..Time.now).count
        },
        {
          name: 'Successes',
          data: FlagLog.auto.where(success: true, is_dry_run: false).group_by_day(:created_at, range: 1.month.ago.to_date..Time.now).count
        }
      ]
    end
    render json: data
  end

  def detailed_ttd
    no_flags = Post.group_by_hour_of_day('`posts`.`created_at`')
                   .select('AVG(TIMESTAMPDIFF(SECOND, `posts`.`created_at`, `deletion_logs`.`created_at`)) as time_to_deletion')
                   .joins(:deletion_logs)
                   .where(is_tp: true)
                   .where('`posts`.`created_at` < ?', Date.new(2017, 1, 1))
                   .where('TIMESTAMPDIFF(SECOND, `posts`.`created_at`, `deletion_logs`.`created_at`) <= 3600').relation.each_with_index
                   .map { |a, i| [i, a.time_to_deletion.round(0)] }
    one_flag = Post.group_by_hour_of_day('`posts`.`created_at`')
                   .select('AVG(TIMESTAMPDIFF(SECOND, `posts`.`created_at`, `deletion_logs`.`created_at`)) as time_to_deletion')
                   .joins(:deletion_logs)
                   .where(is_tp: true)
                   .where('`posts`.`created_at` >= ?', Date.new(2017, 1, 1))
                   .where('`posts`.`created_at` < ?', Date.new(2017, 2, 14))
                   .where('TIMESTAMPDIFF(SECOND, `posts`.`created_at`, `deletion_logs`.`created_at`) <= 3600').relation.each_with_index
                   .map { |a, i| [i, a.time_to_deletion.round(0)] }
    three_flags = Post.group_by_hour_of_day('`posts`.`created_at`')
                      .select('AVG(TIMESTAMPDIFF(SECOND, `posts`.`created_at`, `deletion_logs`.`created_at`)) as time_to_deletion')
                      .joins(:deletion_logs)
                      .where(is_tp: true)
                      .where('`posts`.`created_at` >= ?', Date.new(2017, 2, 14))
                      .where('TIMESTAMPDIFF(SECOND, `posts`.`created_at`, `deletion_logs`.`created_at`) <= 3600').relation.each_with_index
                      .map { |a, i| [i, a.time_to_deletion.round(0)] }
    render json: [
      { name: '0 flags', data: no_flags },
      { name: '1 flag', data: one_flag },
      { name: '3 flags', data: three_flags }
    ]
  end

  def monthly_ttd
    data = cached_query :monthly_ttd_graph do
      Post.group_by_day('`posts`.`created_at`').joins(:deletion_logs)
          .where(is_tp: true).where('`posts`.`created_at` > ?', (params[:months].try(:to_i) || 3).months.ago.to_date)
          .where('TIMESTAMPDIFF(SECOND, `posts`.`created_at`, `posts`.`deleted_at`) <= 3600')
          .average('TIMESTAMPDIFF(SECOND, `posts`.`created_at`, `posts`.`deleted_at`)')
    end
    render json: data
  end

  def reports
    render json: [
      { name: 'All', data: Post.where('created_at > ?', 3.months.ago).group_by_day(:created_at).count },
      { name: 'TP', data: Post.tp.where('created_at > ?', 3.months.ago).group_by_day(:created_at).count },
      { name: 'FP', data: Post.fp.where('created_at > ?', 3.months.ago).group_by_day(:created_at).count }
    ]
  end

  private

  def cached_query(cache_key, **opts)
    opts[:expires_in] ||= 1.hour
    opts[:param_name] ||= :cache
    opts[:always_cache] ||= false

    if opts[:always_cache] || params[opts[:param_name]].present?
      Rails.cache.fetch cache_key, expires_in: opts[:expires_in] do
        yield
      end
    else
      yield
    end
  end
end
