class ChannelsController < ApplicationController
  def receive_email
    render text: "hi SNS!"
  end
end
