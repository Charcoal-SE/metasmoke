# frozen_string_literal: true

class FlagLogController < ApplicationController
  respond_to :html, :js

  def index
    @individual_user = User.find(params[:user_id]) if params[:user_id].present?

    @applicable_flag_logs = if @individual_user
                              @individual_user.flag_logs.where(is_auto: true)
                            else
                              FlagLog.all
                            end

    @applicable_flag_logs = case params[:filter]
                            when 'fps'
                              @applicable_flag_logs.joins(:post)
                                                   .where(success: true)
                                                   .where(posts: { is_tp: false })
                                                   .where('`posts`.`is_fp` = 1 OR `posts`.`is_naa` = 1')
                            when 'failures'
                              @applicable_flag_logs.where(success: false)
                            when 'manual'
                              @individual_user ? @individual_user.flag_logs.where(auto: false) : FlagLog.manual
                            when 'other'
                              @applicable_flag_logs.unscoped.where(flag_type: 'other')
                            else
                              @applicable_flag_logs.auto.spam
                            end

    @flag_logs = @applicable_flag_logs.order(Arel.sql('flag_logs.created_at DESC, flag_logs.id DESC'))
                                      .includes(post: [feedbacks: %i[user api_key]])
                                      .includes(post: [:reasons])
                                      .includes(:user)
                                      .paginate(page: params[:page], per_page: 100)
    @sites = Site.where(id: @flag_logs.map(&:post).map(&:site_id)).to_a
  end

  def by_post
    @individual_post = Post.find(params[:id])
    @flag_logs = @individual_post.flag_logs.where(is_auto: true)
                                 .order(Arel.sql('created_at DESC, id DESC'))
                                 .includes(post: [feedbacks: %i[user api_key]])
                                 .includes(post: [:reasons])
                                 .includes(:user)
                                 .paginate(page: params[:page], per_page: 100)
    @sites = Site.where(id: @flag_logs.map(&:post).map(&:site_id)).to_a
    render :index
  end

  def eligible_flaggers
    @eligible_users = Post.find(params[:id]).eligible_flaggers
  end

  def not_flagged
    @posts = Post.left_joins(:flag_logs)
                 .where(flag_logs: { id: nil })
                 .includes(feedbacks: %i[user api_key])
                 .includes(:reasons)
                 .order(created_at: :desc)
                 .paginate(page: params[:page], per_page: 100)
    @sites = Site.where(id: @posts.map(&:site_id)).to_a
  end
end
