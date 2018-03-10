class ChannelsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def receive_email
    Rails.logger.info "debug"
    Rails.logger.info request.raw_post
    render text: "hi SNS!"
  end
end
