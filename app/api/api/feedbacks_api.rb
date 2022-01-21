# frozen_string_literal: true

module API
  class FeedbacksAPI < API::Base
    get '/' do
      std_result Feedback.all.order(id: :desc), filter: FILTERS[:feedbacks]
    end

    get 'post/:id' do
      std_result Feedback.where(post_id: params[:id]).order(id: :desc), filter: FILTERS[:feedbacks]
    end

    get 'user/:id' do
      std_result Feedback.where(user_id: params[:id]).order(id: :desc), filter: FILTERS[:feedbacks]
    end

    get 'app/:id' do
      std_result Feedback.where(api_key_id: params[:id]).order(id: :desc), filter: FILTERS[:feedbacks]
    end

    before do
      authenticate_user!
      role :reviewer
    end
    params do
      requires :key, type: String
      requires :token, type: String
      requires :type, type: String
    end
    post 'post/:id/create' do
      post = Post.find params[:id]
      feedback = Feedback.new user: current_user, post: post, api_key: @key, feedback_type: params[:type]

      if post.question? && feedback.is_naa?
        error!({ name: 'illegal', detail: 'NAA feedback is not allowed on questions.' },
               400)
      end

      if feedback.save
        if feedback.is_naa?
          begin
            ActionCable.server.broadcast 'smokedetector_messages', naa: { post_link: @post.link }
          rescue
            nil
          end
        elsif feedback.is_negative?
          begin
            ActionCable.server.broadcast 'smokedetector_messages', fp: { post_link: @post.link }
          rescue
            nil
          end
        end

        std_result post.feedbacks.order(id: :desc), filter: FILTERS[:feedbacks]
      else
        error!({ name: 'persistence_fail', detail: 'Feedback object failed to save.' }, 500)
      end
    end
  end
end
