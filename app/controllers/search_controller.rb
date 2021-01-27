# frozen_string_literal: true

class SearchController < ApplicationController
  def index
    # This might be ugly, but it's better than the alternative.
    #
    # And it's kinda clever.

    title, title_operation,
    body, body_operation,
    why, why_operation,
    username, username_operation = %i[title body why username].map do |s|
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
     [:why, why, why_operation]].each do |si|
      if si[1].present? && si[1] != '%%'
        search_string << "IFNULL(`posts`.`#{si[0]}`, '') #{si[2]} :#{si[0]}"
        search_params[si[0]] = si[1]
      end
    end

    if body.present?
      if ['LIKE', 'NOT LIKE'].include?(body_operation) && params[:body_is_like] != '1'
        # If the operation would be LIKE, hijack it and use our fulltext index for a search instead.
        # UNLESS... params[:body_is_like] is set, in which case the user has explicitly specified a LIKE query.
        @results = @results.match_search(body, with_search_score: false, posts: :body)
      else
        if params[:body_is_like] == '1' && !user_signed_in?
          flash[:warning] = 'Unregistered users cannot use LIKE searches on the body field. Please sign in.'
          redirect_to(search_path) && return
        end
        # Otherwise, it's REGEX or NOT REGEX, which fulltext won't do - fall back on search_string and params
        search_string << "IFNULL(`posts`.`body`, '') #{body_operation} :body"
        search_params[:body] = body.present? ? body : '%%'
      end
    end

    @results = @results.where(search_string.join(params[:or_search].present? ? ' OR ' : ' AND '), **search_params)
    @results = @results.includes(:reasons).includes(:feedbacks) if params[:option].nil?

    if params[:has_no_feedback] == '1'
      @results = @results.joins('LEFT JOIN feedbacks fbcounter ON fbcounter.post_id = posts.id').where('fbcounter.id is null')
    end

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

    @results = @results.where('revision_count > 1') if params[:edited].present?

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
        @counts_by_feedback = %i[is_tp is_fp is_naa].each_with_index.map do |symbol, i|
          [symbol, @counts_by_accuracy_group.select { |k, _v| k[i] }.values.sum]
        end.to_h
        @total_count = @counts_by_accuracy_group.values.sum

        @results = case params[:feedback_filter]
                   when 'tp'
                     @results.where(is_tp: true)
                             .paginate(page: params[:page], per_page: per_page,
                                       total_entries: @counts_by_feedback[:is_tp])
                   when 'fp'
                     @results.where(is_fp: true)
                             .paginate(page: params[:page], per_page: per_page,
                                       total_entries: @counts_by_feedback[:is_fp])
                   when 'naa'
                     @results.where(is_naa: true)
                             .paginate(page: params[:page], per_page: per_page,
                                       total_entries: @counts_by_feedback[:is_naa])
                   else
                     @results.paginate(page: params[:page], per_page: per_page,
                                       total_entries: @total_count)
                   end.order(Arel.sql('`posts`.`created_at` DESC'))

        render :search
      end
      format.json do
        render json: @results
      end
      format.rss { render :search, layout: false }
      format.xml { render 'search.rss', layout: false }
    end
  end
end
