require 'test_helper'

class BlacklistControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  test "shouldn't allow blank websites" do
    sign_in users(:code_admin_user)

    assert_raises ActiveRecord::RecordInvalid do
      post :create_website, params: {:blacklisted_website => {:host => ""}}
    end
  end
end
