# frozen_string_literal: true

class SearchController < ApplicationController
  def index
    # This might be ugly, but it's better than the alternative.
    #
    # And it's kinda clever.

    title, title_operation,
    body, body_operation,
    why, why_operation,
    username, username_operation = [:title, :body, :why, :username].map do |s|
      SearchHelper.parse_search_params(params, s, current_user)
    end.flatten

    if [title_operation, body_operation, why_operation, username_operation].any?(&:!)
      render json: { error: 'Unauthenticated users cannot use regex search' }, status: 403
      return
    end

    user_reputation = params[:user_reputation].to_i || 0

    case params[:feedback]
    when /true/
      feedback = :is_tp
    when /false/
      feedback = :is_fp
    when /NAA/
      feedback = :is_naa
    end

    @results = if params[:reason].present?
                 Reason.find(params[:reason]).posts.includes_for_post_row
               else
                 Post.all.includes_for_post_row
               end

    per_page = user_signed_in? && params[:per_page].present? ? [params[:per_page].to_i, 10_000].min : 100

    search_string = []
    search_params = {}
    [[:username, username, username_operation], [:title, title, title_operation],
     [:body, body, body_operation], [:why, why, why_operation]].each do |si|
      search_string << "IFNULL(`posts`.`#{si[0]}`, '') #{si[2]} :#{si[0]}"
      search_params[si[0]] = si[1]
    end
    @results = @results.where(search_string.join(' AND '), **search_params)
                       .paginate(page: params[:page], per_page: per_page)
                       .order(Arel.sql('`posts`.`created_at` DESC'))

    @results = @results.includes(:reasons).includes(:feedbacks) if params[:option].nil?

    if feedback.present?
      @results = @results.where(feedback => true)
    elsif params[:feedback] == 'conflicted'
      @results = @results.where(is_tp: true, is_fp: true)
    end

    @results = case params[:user_rep_direction]
               when '>='
                 if user_reputation > 0
                   @results.where('IFNULL(user_reputation, 0) >= :rep', rep: user_reputation)
                 end
               when '=='
                 @results.where('IFNULL(user_reputation, 0) = :rep', rep: user_reputation)
               when '<='
                 @results.where('IFNULL(user_reputation, 0) <= :rep', rep: user_reputation)
               else
                 @results
               end

    @results = @results.where(site_id: params[:site]) if params[:site].present?

    @results = @results.includes(feedbacks: [:user])

    case params[:autoflagged].try(:downcase)
    when 'yes'
      @results = @results.autoflagged
    when 'no'
      @results = @results.not_autoflagged
    end

    post_type = case params[:post_type].try(:downcase).try(:[], 0)
                when 'q'
                  'questions'
                when 'a'
                  'a'
                end

    if post_type.present?
      unmatched = @results.where.not("link LIKE '%/questions/%' OR link LIKE '%/a/%'")
      @results =  if params[:post_type_include_unmatched]
                    @results.where('link like ?', "%/#{post_type}/%").or(unmatched)
                  else
                    @results.where('link like ?', "%/#{post_type}/%")
                  end
    end

    respond_to do |format|
      format.html do
        @counts_by_accuracy_group = @results.group(:is_tp, :is_fp, :is_naa).count
        @counts_by_feedback = [:is_tp, :is_fp, :is_naa].each_with_index.map do |symbol, i|
          [symbol, @counts_by_accuracy_group.select { |k, _v| k[i] }.values.sum]
        end.to_h

        case params[:feedback_filter]
        when 'tp'
          @results = @results.where(is_tp: true)
        when 'fp'
          @results = @results.where(is_fp: true)
        when 'naa'
          @results = @results.where(is_naa: true)
        end

        @sites = Site.where(id: @results.map(&:site_id)).to_a unless params[:option] == 'graphs'
        render :search
      end
      format.json do
        render json: @results
      end
      format.rss { render :search, layout: false }
      format.xml { render 'search.rss', layout: false }
    end
  end

  def index_fast
    title, title_operation,
    body, body_operation,
    why, why_operation,
    username, username_operation = [:title, :body, :why, :username].map do |s|
      SearchHelper.parse_search_params(params, s, current_user)
    end.flatten

    redis_expiry_time = params[:redis_expiry].present? ? [params[:redis_expire].to_i, 600] : 120

    if [title_operation, body_operation, why_operation, username_operation].any?(&:!)
      render json: { error: 'Unauthenticated users cannot use regex search' }, status: 403
      return
    end

    user_reputation = params[:user_reputation].to_i || 0

    feedback = case params[:feedback]
               when /true/
                 :is_tp
               when /false/
                 :is_fp
               when /NAA/
                 :is_naa
    end

    per_page = user_signed_in? && params[:per_page].present? ? [params[:per_page].to_i, 10_000].min : 100

    page = params[:page].to_i
    page = 1 if page == 0

    npage = [(page - 1) * per_page, page * per_page]

    @logs = []
    @logs.push("PAGE: #{page}")
    @logs.push("PER_PAGE: #{per_page}")
    @logs.push("NPAGE: #{npage}")

    intersect = %w[]
    subtract = %w[]

    intersect.push "reasons/#{params[:reason].to_i}" if params[:reason].present?

    if feedback.present?
      intersect.push "#{feedback.to_s[3..-1]}s"
    elsif params[:feedback] == 'conflicted'
      intersect.push 'tps'
      intersect.push 'fps'
    end

    case params[:autoflagged].try(:downcase)
    when 'yes'
      intersect.push('autoflagged')
    when 'no'
      subtract.push('autoflagged')
    end

    case params[:post_type].try(:downcase).try(:[], 0)
    when 'q'
      intersect.push('questions')
    when 'a'
      instersect.push('answers')
    end

    # Just note, you forgot about user_rep, but do we really need that?

    intersect.push("sites/#{params[:site].to_i}/posts") if params[:site].present?

    search_id = redis.incr 'search_counter'
    if intersect.empty?
      dkey = 'all_posts'
    else
      dkey = "user_searches/#{search_id}/intersect"
      redis.sinterstore dkey, 'all_posts', *intersect
    end
    if subtract.empty?
      skey = dkey
    else
      skey = "user_searches/#{search_id}/subtract"
      redis.sdiffstore(skey, dkey, *subtract)
      redis.expire dkey, redis_expiry_time unless dkey == 'all_posts'
    end
    fkey = "user_searches/#{search_id}/simple_result"
    # This converts it to a ZSET, before this we were working with a SET
    redis.zinterstore(fkey, ['posts', skey], aggregate: 'max')
    redis.expire skey, redis_expiry_time unless skey == 'all_posts'

    # Make 3 tmpsets then intersect them
    to_expire = []
    [
      ['stack_exchange_user_username', username, username_operation],
      ['title', title, title_operation],
      ['body', body, body_operation],
      ['why', why, why_operation]
    ].each do |type, constraint, op|
      next if params[type.split('_').last].nil?
      tkey = "user_searches/#{search_id}/#{type}"
      to_expire.push(tkey)
      case op
      when 'REGEXP'
        redis.zhregex fkey, tkey, 'posts/', type.to_s, params["#{type}_is_case_sensitive"] ? constraint : "(?i)#{constraint}"
      when 'NOT REGEXP'
        redis.zhregex fkey, tkey, 'posts/', type.to_s, params["#{type}_is_case_sensitive"] ? constraint : "(?i)#{constraint}", 'INVERT'
      when 'LIKE'
        redis.zhregex fkey, tkey, 'posts/', type.to_s, constraint[1..-2], 'LIKE'
      end
    end
    redis.expire fkey, redis_expiry_time

    final_key = "user_searches/#{search_id}/final"
    @nresults = if to_expire.empty?
                  []
                else
                  redis.zunionstore final_key, cols
                  redis.zrevrange(final_key, 0, -1)
    end
    to_expire.each { |k| redis.expire k, redis_expiry_time }

    @logs.push "Result count: #{@nresults.length}"

    # Technically we should wait until later to reset these, but eh.
    redis.expire final_key, redis_expiry_time
    redis.expire 'search_counter', 2400

    count = @nresults.length

    @results = @nresults.drop(npage.min).take(npage.max).map { |i| Redis::Post.new(i) }
    @results.define_singleton_method(:total_pages) { (count / per_page) + 1 }
    @results.define_singleton_method(:current_page) { page }

    respond_to do |format|
      format.html do
        to_expire = []
        result_keys = %i[tp fp naa].map do |sym|
          key = "user_searches/#{search_id}/counts_by_feedback/#{sym}s"
          redis.zinterstore key, [final_key, "#{sym}s"]
          to_expire.push(key)
          [sym, key]
        end.to_h

        @counts_by_feedback = result_keys.map { |n, k| [:"is_#{n}", redis.zcard(k)] }.to_h

        to_expire.each { |k| redis.expire(k, redis_expiry_time) }

        @result_count = redis.zcard final_key

        case params[:feedback_filter]
        when 'tp'
          @results = @results.select(&:is_tp)
        when 'fp'
          @results = @results.select(&:is_fp)
        when 'naa'
          @results = @results.select(&:is_naa)
        end

        @sites = Site.where(id: @results.map(&:site_id)).to_a unless params[:option] == 'graphs'
        render :search_fast
      end
      format.json { render json: @results }
      format.rss  { render :search, layout: false }
      format.xml  { render 'search.rss', layout: false }
    end
  end
end
