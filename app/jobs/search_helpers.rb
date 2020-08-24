# frozen_string_literal: true

SEARCH_PAGE_LENGTH = 10_000
VALID_SEARCH_PARAMS = %i[
  post_type_include_unmatched autoflagged post_type user_rep_direction
  site edited or_search option body_is_like user_reputation reason feedback
].freeze
SEARCH_JOB_TIMEOUT = (60 * 60 * 3)
SEACH_PAGE_EXPIRATION = 1.hour
module SearchJobQueryBuilder
  def build_query(ops, wrapped_params)
    title, title_operation,
    body, body_operation,
    why, why_operation,
    username, username_operation = ops

    user_reputation = wrapped_params[:user_reputation].to_i || 0

    case wrapped_params[:feedback]
    when /true/
      feedback = :is_tp
    when /false/
      feedback = :is_fp
    when /NAA/
      feedback = :is_naa
    end

    results = if wrapped_params[:reason].present?
                Reason.find(wrapped_params[:reason]).posts
              else
                Post.all
              end

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
      if ['LIKE', 'NOT LIKE'].include?(body_operation) && wrapped_params[:body_is_like] != '1'
        # If the operation would be LIKE, hijack it and use our fulltext index for a search instead.
        # UNLESS... params[:body_is_like] is set, in which case the user has explicitly specified a LIKE query.
        results = results.match_search(body, with_search_score: false, posts: :body)
      else
        if wrapped_params[:body_is_like] == '1' && !user_signed_in?
          flash[:warning] = 'Unregistered users cannot use LIKE searches on the body field. Please sign in.'
          redirect_to(search_path) && return
        end
        # Otherwise, it's REGEX or NOT REGEX, which fulltext won't do - fall back on search_string and params
        search_string << "IFNULL(`posts`.`body`, '') #{body_operation} :body"
        search_params[:body] = body.present? ? body : '%%'
      end
    end

    results = results.where(search_string.join(wrapped_params[:or_search].present? ? ' OR ' : ' AND '), **search_params)

    # results = results.includes(:reasons).includes(:feedbacks) if wrapped_params[:option].nil?
    results = results.joins(:reasons).joins(:feedbacks) if wrapped_params[:option].nil?

    if feedback.present?
      results = results.where(feedback => true)
    elsif wrapped_params[:feedback] == 'conflicted'
      results = results.where(is_tp: true, is_fp: true)
    end

    results = case wrapped_params[:user_rep_direction]
              when '>='
                if user_reputation > 0
                  results.where('IFNULL(user_reputation, 0) >= :rep', rep: user_reputation)
                end
              when '=='
                results.where('IFNULL(user_reputation, 0) = :rep', rep: user_reputation)
              when '<='
                results.where('IFNULL(user_reputation, 0) <= :rep', rep: user_reputation)
              else
                results
              end

    results = results.where(site_id: wrapped_params[:site]) if wrapped_params[:site].present?

    results = results.where('revision_count > 1') if wrapped_params[:edited].present?

    # results = results.includes(feedbacks: [:user])

    case wrapped_params[:autoflagged].try(:downcase)
    when 'yes'
      results = results.autoflagged
    when 'no'
      results = results.not_autoflagged
    end

    post_type = case wrapped_params[:post_type].try(:downcase).try(:[], 0)
                when 'q'
                  'questions'
                when 'a'
                  'a'
                end

    if post_type.present?
      unmatched = results.where.not("link LIKE '%/questions/%' OR link LIKE '%/a/%'")
      results = if wrapped_params[:post_type_include_unmatched]
                  results.where('link like ?', "%/#{post_type}/%").or(unmatched)
                else
                  results.where('link like ?', "%/#{post_type}/%")
                end
    end

    results.distinct.order(Arel.sql('`posts`.`created_at` DESC'))
  end
end
