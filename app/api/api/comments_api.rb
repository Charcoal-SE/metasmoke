# frozen_string_literal: true

module API
  class CommentsAPI < API::BaseWithAuth
    get '/' do
      std_result PostComment.all.order(id: :desc), filter: FILTERS[:comments]
    end

    get 'post/:id' do
      std_result PostComment.where(post_id: params[:id]).order(id: :desc), filter: FILTERS[:comments]
    end

    params do
      requires :key, type: String
      requires :token, type: String
      requires :text, type: String
    end
    post 'post/:id/add' do
      authenticate_user!

      comment = PostComment.create(post_id: params[:id], text: params[:text], user: current_user)
      single_result comment
    end

    params do
      requires :key, type: String
      requires :text, type: String
      requires :chat_user_id, type: Integer
      requires :chat_host, type: String
    end
    post 'post/:id' do
      authenticate_smokey!

      id_field = { 'stackexchange.com' => :stackexchange_chat_id, 'stackoverflow.com' => :stackoverflow_chat_id,
                   'meta.stackexchange.com' => :meta_stackexchange_chat_id }[params[:chat_host]]
      error!({ name: 'bad_parameter', detail: 'chat_host is unrecognized' }, 400) if id_field.nil?

      user = User.find_by(id_field => params[:chat_user_id]) || User.find(-1)
      comment = PostComment.create(user: user, post_id: params[:id], text: params[:text])

      single_result comment
    end
  end
end
