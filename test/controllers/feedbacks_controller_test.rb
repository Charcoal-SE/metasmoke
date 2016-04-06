require 'test_helper'

class FeedbacksControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  test "should allow admin to clear feedback" do
    sign_in users(:admin_user)

    get :clear, params: { :id => Post.last.id }
    assert_response :success
  end

  test "should not allow non-admins to clear feedback" do
    sign_out :user
    get :clear, params: { :id => Post.last.id }
    assert_redirected_to new_user_session_url

    assert_raises ActionController::RoutingError do
      sign_in users(:approved_user)
      get :clear, params: { :id => Post.last.id }
      assert_response :not_found
    end
  end
end
