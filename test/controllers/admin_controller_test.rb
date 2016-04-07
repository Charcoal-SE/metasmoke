require 'test_helper'

class AdminControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  test "should get index" do
    sign_in users(:admin_user)
    get :index
    assert_response :success
  end

  test "should require admin privileges to view page" do
    sign_out :user
    assert_raises ActionController::RoutingError do
      get :index
    end

    sign_in users(:approved_user)
    assert_raises ActionController::RoutingError do
      get :index
    end
  end

  test "should get invalidated page" do
    sign_in users(:admin_user)

    get :recently_invalidated
    assert_response :success
  end

  test "should get user feedback page" do
    sign_in users(:admin_user)

    get :user_feedback, params: { :user_name => Feedback.where("user_name IS NOT NULL").first.user_name }
    assert_response :success
    assert assigns(:feedbacks)
  end
end
