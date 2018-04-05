# frozen_string_literal: true

class ChannelsController < ApplicationController
  before_action :authenticate_user!, except: [:receive_email]
  skip_before_action :verify_authenticity_token, only: [:receive_email]

  # rubocop:disable Style/AccessorMethodName
  def get_email_address
    if current_user.channels_user.present?
      @secret = current_user.channels_user.secret
    elsif current_user.roles.count == 0
      flash[:danger] = 'You are not permitted to sign up to Channels.'
      redirect_to root_path
    else
      @secret = nil
      used = ChannelsUser.all.map(&:secret)
      while @secret.nil?
        attempt = SecureRandom.hex 18
        @secret = attempt unless used.include? attempt
      end

      ChannelsUser.create user: current_user, secret: @secret
    end
  end
  # rubocop:enable Style/AccessorMethodName

  def show_link
    if current_user.channels_user.present?
      @channels_user = current_user.channels_user
    else
      flash[:danger] = "You haven't signed up for Channels yet."
      redirect_to channels_email_path
    end
  end

  def receive_email
    message = JSON.parse(JSON.parse(request.raw_post)['Message'])

    user = message['mail']['destination'][0].split('@')[0]
    text = Base64.decode64(message['content']).gsub('=\r\n', '').gsub('3D', '')
    link = text.scan(%r{(https:\/\/stackoverflow.com\/c\/charcoal\/join\/confirmation\?token=[a-z0-9-]{36})})[0][0]

    ChannelsUser.find_by(secret: user).update(link: link)

    render plain: 'hi SNS!'
  end
end
