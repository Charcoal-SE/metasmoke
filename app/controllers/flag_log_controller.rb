# frozen_string_literal: true

class FlagLogController < ApplicationController
  respond_to :html, :js

  def index
    @individual_user = User.find(params[:user_id]) if params[:user_id].present?

    @applicable_flag_logs = if @individual_user
                              @individual_user.flag_logs.where(is_auto: true)
                            else
                              FlagLog.auto
                            end

    case params[:filter]
    when 'fps'
      @applicable_flag_logs = @applicable_flag_logs.joins(:post)
                                                   .where(success: true)
                                                   .where(posts: { is_tp: false })
                                                   .where('`posts`.`is_fp` = 1 OR `posts`.`is_naa` = 1')
    when 'failures'
      @applicable_flag_logs = @applicable_flag_logs.where(success: false)
    when 'manual'
      @applicable_flag_logs = @individual_user ? @individual_user.flag_logs.where(auto: false) : FlagLog.manual
    end

    @flag_logs = @applicable_flag_logs.order(Arel.sql('flag_logs.created_at DESC, flag_logs.id DESC'))
                                      .includes(post: [feedbacks: [:user, :api_key]])
                                      .includes(post: [:reasons])
                                      .includes(:user)
                                      .paginate(page: params[:page], per_page: 100)
    @sites = Site.where(id: @flag_logs.map(&:post).map(&:site_id)).to_a
  end

  def by_post
    @individual_post = Post.find(params[:id])
    @flag_logs = @individual_post.flag_logs.where(is_auto: true)
                                 .order(Arel.sql('created_at DESC, id DESC'))
                                 .includes(post: [feedbacks: [:user, :api_key]])
                                 .includes(post: [:reasons])
                                 .includes(:user)
                                 .paginate(page: params[:page], per_page: 100)
    @sites = Site.where(id: @flag_logs.map(&:post).map(&:site_id)).to_a
    render :index
  end

  def eligible_flaggers
    @individual_post = Post.find(params[:id])
    conditions = @individual_post.site.flag_conditions.where(flags_enabled: true)
    available_user_ids = {}
    conditions.each do |condition|
      if condition.validate!(@individual_post)
        available_user_ids[condition.user.id] = condition
      end
    end

    uids = @individual_post.site.user_site_settings.where(user_id: available_user_ids.keys).map(&:user_id)
    @eligible_users = User.where(id: uids, flags_enabled: true).where.not(encrypted_api_token: nil)
  end

  def not_flagged
    @posts = Post.left_joins(:flag_logs)
                 .where(flag_logs: { id: nil })
                 .includes(feedbacks: [:user, :api_key])
                 .includes(:reasons)
                 .order(created_at: :desc)
                 .paginate(page: params[:page], per_page: 100)
    @sites = Site.where(id: @posts.map(&:site_id)).to_a
  end
end
