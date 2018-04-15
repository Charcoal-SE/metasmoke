# frozen_string_literal: true

class SearchController < ApplicationController
  def index
    # This might be ugly, but it's better than the alternative.
    #
    # And it's kinda clever.

    title, title_operation,
    why, why_operation,
    username, username_operation = [:title, :why, :username].map do |s|
      SearchHelper.parse_search_params(params, s, current_user)
    end.flatten

    if [title_operation, why_operation, username_operation].any?(&:!)
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
                 Reason.find(params[:reason]).posts
               else
                 Post.all
               end

    per_page = user_signed_in? && params[:per_page].present? ? [params[:per_page].to_i, 10_000].min : 100

    @results = @results.where("IFNULL(posts.username, '') #{username_operation} :username"\
                              " AND IFNULL(title, '') #{title_operation} :title"\
                              " AND IFNULL(why, '') #{why_operation} :why",
                              username: username, title: title, why: why)
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
                 @results.where('ifnull(user_reputation, 0) >= :rep', rep: user_reputation)
               when '=='
                 @results.where('ifnull(user_reputation, 0) = :rep', rep: user_reputation)
               when '<='
                 @results.where('ifnull(user_reputation, 0) <= :rep', rep: user_reputation)
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

    unmatched = @results.where.not("link like '%/questions/%' OR link like '%/a/%'")
    @results =  if params[:post_type_include_unmatched]
                  @results.where('link like ?', "%/#{post_type}/%").or(unmatched)
                else
                  @results.where('link like ?', "%/#{post_type}/%")
                end

    if params[:body].present? && params[:body_is_regex] == '1' && current_user&.can_use_regex_search?
      if params[:body_precursor].present?
        @results = @results.where('MATCH(body) AGAINST (? IN BOOLEAN MODE)', params[:body_precursor])
      end
      @results = @results.select { |p| p.body.present? && p.body.match?(Regexp.new(params[:body], Regexp::IGNORECASE)) }
      @results = Post.where(id: @results.map(&:id))
    elsif params[:body].present?
      @results = @results.where('MATCH(body) AGAINST (? IN BOOLEAN MODE)', params[:body])
    end

    @results = @results.includes_for_post_row

    @results_count = @results.count
    @counts_by_feedback = [:is_tp, :is_fp, :is_naa].map do |s|
      [s, @results.where(s => true).count]
    end.to_h

    case params[:feedback_filter]
      when 'tp'
        @results = @results.where(is_tp: true)
      when 'fp'
        @results = @results.where(is_fp: true)
      when 'naa'
        @results = @results.where(is_naa: true)
    end

    respond_to do |format|
      format.html do
        @results = @results.paginate(page: params[:page], per_page: 100)
        @sites = Site.where(id: @results.map(&:site_id)).to_a unless params[:option] == 'graphs'
        render :search
      end
      format.json do
        render json: @results
      end
      format.rss { render :search, layout: false }
    end
  end
end
