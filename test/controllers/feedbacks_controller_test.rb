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

  test "should mark cleared feedback invalidated" do
    sign_in users(:admin_user)
    delete :delete, params: { :id => Feedback.last.id }
    assert Feedback.unscoped.last.is_invalidated?
  end

  test "should not delete cleared feedback" do
    assert_no_difference 'Feedback.unscoped.count' do
      sign_in(:admin_user)
      delete :delete, params: { :id => Feedback.last.id }
    end
  end

  test "should redirect to clear page after deleting" do
    sign_in users(:admin_user)
    id = Feedback.last.id
    post_id = Feedback.last.post.id
    delete :delete, params: { :id => id }
    assert_redirected_to clear_post_feedback_url(post_id)
  end

  test "should attribute invalidations" do
    user = users(:admin_user)
    f_id = Feedback.last.id
    sign_in user

    delete :delete, params: { :id => f_id }

    assert_equal Feedback.unscoped.find(f_id).invalidated_by, user.id
  end
end
