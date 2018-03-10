# frozen_string_literal: true

class ChannelsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def receive_email
    message = JSON.parse(JSON.parse(request.raw_post)['Message'])

    user = message['mail']['destination'][0].split('@')[0]
    text = Base64.decode64(message['content']).gsub('=\r\n', '').gsub('3D', '')
    link = text.scan(%r{(https:\/\/stackoverflow.com\/c\/charcoal\/join\/confirmation\?token=[a-z0-9-]{36})})[0][0]

    SmokeDetector.send_message_to_charcoal("@#{user} Your Channels join link: #{link}")

    render plain: 'hi SNS!'
  end
end
