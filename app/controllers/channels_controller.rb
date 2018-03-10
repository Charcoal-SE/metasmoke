class ChannelsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def receive_email
    puts params
    render text: "hi SNS!"
  end
end
