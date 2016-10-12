require 'test_helper'

class BlacklistControllerTest < ActionController::TestCase
  test "shouldn't allow blank websites" do
    sign_in users(:code_admin_user)

    assert_raises ActiveRecord::RecordInvalid do
      post :create_website, params: {:blacklisted_website => {:host => ""}}
    end
  end

  test "should load index" do
    sign_in users(:code_admin_user)
    get :index
    assert_response :success
  end
end
