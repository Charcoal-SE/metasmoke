class SearchController < ApplicationController
  def search_results
    # This might be ugly, but it's better than the alternative.
    #
    # And it's kinda clever.

    title, title_operation,
      body, body_operation,
      why, why_operation,
      username, username_operation = [:title, :body, :why, :username].map do |s|
        SearchHelper.parse_search_params(params, s, user_signed_in?)
      end.flatten

    user_reputation = params[:user_reputation].to_i || 0

    case params[:feedback]
      when /true/
        feedback = :is_tp
      when /false/
        feedback = :is_fp
      when /NAA/
        feedback = :is_naa
    end

    if params[:reason].present?
      @results = Reason.find(params[:reason]).posts.includes_for_post_row
    else
      @results = Post.all.includes_for_post_row
    end

    per_page = (user_signed_in? and params[:per_page].present?) ? [params[:per_page].to_i, 10000].min : 100

    @results = @results.where("IFNULL(posts.username, '') " + username_operation + " :username AND IFNULL(title, '') " + title_operation + " :title AND IFNULL(body, '') " + body_operation + " :body AND IFNULL(why, '') " + why_operation + " :why", username: username, title: title, body: body, why: why)
                   .paginate(:page => params[:page], :per_page => per_page)
                   .order("`posts`.`created_at` DESC")

    if params[:option].nil?
      @results = @results.includes(:reasons).includes(:feedbacks)
    end

    if feedback.present?
      @results = @results.where(feedback => true)
    elsif params[:feedback] == "conflicted"
      @results = @results.where(:is_tp => true, :is_fp => true)
    end

    @results = case params[:user_rep_direction]
      when ">="
        @results.where("ifnull(user_reputation, 0) >= :rep", rep: user_reputation)
      when "=="
        @results.where("ifnull(user_reputation, 0) = :rep", rep: user_reputation)
      when "<="
        @results.where("ifnull(user_reputation, 0) <= :rep", rep: user_reputation)
      else
        @results
    end

    if params[:site].present?
      @results = @results.where(:site_id => params[:site])
    end

  @results = @results.includes(:feedbacks => [:user])

  case params[:autoflagged].try(:downcase)
  when "yes"
    @results = @results.autoflagged
  when "no"
    @results = @results.not_autoflagged
  end

  respond_to do |format|
      format.html {
        @counts_by_accuracy_group = @results.group(:is_tp, :is_fp, :is_naa).count
        @counts_by_feedback = [:is_tp, :is_fp, :is_naa].each_with_index.map do |symbol, i|
          [symbol, @counts_by_accuracy_group.select { |k, v| k[i] }.values.sum]
        end.to_h

        case params[:feedback_filter]
        when 'tp'
          @results = @results.where(:is_tp => true)
        when 'fp'
          @results = @results.where(:is_fp => true)
        when 'naa'
          @results = @results.where(:is_naa => true)
        end

        @sites = Site.where(:id => @results.map(&:site_id)).to_a unless params[:option] == "graphs"
        render :search
      }
      format.json {
        render json: @results
      }
    end
  end
end
