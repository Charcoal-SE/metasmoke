# frozen_string_literal: true

class AdminController < ApplicationController
  before_action :verify_admin, only: %i[permissions update_permissions destroy_user]
  before_action :verify_developer, only: :destroy_user

  def index; end

  def recently_invalidated
    @feedbacks = Feedback.unscoped.includes(:invalidated_by)
                         .joins('inner join posts on feedbacks.post_id = posts.id')
                         .where(is_invalidated: true)
                         .select(Arel.sql('posts.title, feedbacks.*'))
                         .order(Arel.sql('feedbacks.invalidated_at DESC'))
                         .paginate(page: params[:page], per_page: 100)
  end

  def user_feedback
    @user = User.all.where(id: params[:user_id]).first
    @feedback = Feedback.unscoped
                        .joins('inner join posts on feedbacks.post_id = posts.id')
                        .where(user_id: @user.id)
                        .select(Arel.sql('posts.title, feedbacks.*'))
    @sources = ['metasmoke']

    @sources << 'Stack Overflow chat' if @user.stackoverflow_chat_id.present?

    @sources << 'Stack Exchange chat' if @user.stackexchange_chat_id.present?

    @sources << 'Meta Stack Exchange chat' if @user.meta_stackexchange_chat_id.present?

    @feedback = @feedback.order(Arel.sql('feedbacks.id DESC')).paginate(page: params[:page], per_page: 1000)
    @feedback_count = @feedback.count
    @invalid_count = @feedback.where(is_invalidated: true).count
    @feedback_count_today = @feedback.where('feedbacks.updated_at > ?', Date.today).count
  end

  def users
    @roles = Role.names
    @users = if params[:filter].present?
               User.where('username LIKE ?', "%#{params[:filter]}%")
             else
               User.all
             end.includes(:roles).paginate(page: params[:page], per_page: 100)
  end

  def api_feedback
    @feedback = Feedback.via_api.includes(:user, :post).order(created_at: :desc).paginate(page: params[:page],
                                                                                          per_page: 100)
  end

  def permissions
    redirect_to action: :users
  end

  def update_permissions
    if params[:permitted] == 'true'
      if params[:role] == 'developer'
        render plain: 'you must be a developer', status: :forbidden
        return
      end

      if params[:pinned]
        User.find(params[:user_id]).add_pinned_role params[:role]
      else
        User.find(params[:user_id]).add_role params[:role]
      end
    else
      User.find(params[:user_id]).remove_role params[:role]
    end

    render plain: 'success', status: :accepted
  end

  def destroy_user
    User.find(params[:user_id]).destroy
    render plain: 'success', status: :accepted
  end
end
