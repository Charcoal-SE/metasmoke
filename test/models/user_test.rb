# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'user record should be deletable' do
    post = Post.last

    u = User.new
    u.username = 'Awesome Name'
    u.save!(validate: false)

    u.flag_conditions.new.save!(validate: false)
    u.flag_logs.new.save!(validate: false)
    u.api_tokens.new.save!(validate: false)
    u.api_keys.new.save!(validate: false)
    u.user_site_settings.new.save!(validate: false)
    u.feedbacks.new(feedback_type: 'tpu-', post: post).save!(validate: false)
    u.smoke_detectors.new.save!(validate: false)
    u.moderator_sites.new.save!(validate: false)

    assert_difference 'User.count', -1 do
      u.destroy!
    end
  end
end
