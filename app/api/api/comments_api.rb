# frozen_string_literal: true

module API
  class CommentsAPI < API::Base
    get '/' do
      std_result PostComment.all.order(id: :desc), filter: FILTERS[:comments]
    end

    get 'post/:id' do
      std_result PostComment.where(post_id: params[:id]).order(id: :desc), filter: FILTERS[:comments]
    end

    before do
      authenticate_smokey!
    end
    params do
      requires :key, type: String
      requires :text, type: String
      requires :chat_user_id, type: Integer
      requires :chat_host, type: String
    end
    post 'post/:id' do
      id_field = { 'chat.stackexchange.com' => :stackexchange_chat_id, 'chat.stackoverflow.com' => :stackoverflow_chat_id,
                   'chat.meta.stackexchange.com' => :meta_stackexchange_chat_id }[params[:chat_host]]
      user = User.find_by(id_field => params[:chat_user_id]) || User.find(-1)
      comment = PostComment.create(user: user, post_id: params[:id], text: params[:text])

      single_result comment
    end
  end
end
