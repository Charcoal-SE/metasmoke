require 'test_helper'

class FeedbacksControllerTest < ActionController::TestCase
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

  test "should require smokedetector key to create feedback" do
    post :create, params: { :feedback => {} }
    assert_response :forbidden

    post :create, params: { :feedback => {}, :key => "wrongkey" }
    assert_response :forbidden
  end

  test "should create feedback" do
    assert_difference ['Post.last.feedbacks.count', 'Feedback.count'] do
      post :create, params: { :feedback => { :message_link => "foo", :user_name => "Undo", :user_link => "http://foo.bar/undo", :feedback_type => "tpu-", :post_link => Post.last.link, :chat_user => 12345 }, :key => SmokeDetector.last.access_token }
    end
  end

  test "should ignore identical feedback from the same user" do
    # assert_difference looks for a delta of 1; a delta of 2 would error out
    assert_difference ['Post.last.feedbacks.count', 'Feedback.count'] do
      3.times do
        post :create, params: { :feedback => { :message_link => "foo", :user_name => "Undo", :user_link => "http://foo.bar/undo", :feedback_type => "tpu-", :post_link => Post.last.link, :chat_user => 12345 }, :key => SmokeDetector.last.access_token }
      end
    end
  end

  test "should not ignore unidentical feedback from the same user" do
    Post.last.feedbacks.destroy_all

    assert_difference ['Post.last.feedbacks.count', 'Feedback.count'], 2 do
      ["tpu-", "fpu-"].each do |feedback_type|
        post :create, params: { :feedback => { :message_link => "foo", :user_name => "Undo", :user_link => "http://foo.bar/undo", :feedback_type => feedback_type, :post_link => Post.last.link, :chat_user => 12345 }, :key => SmokeDetector.last.access_token }
      end
    end
  end

  test "should cache feedback" do
    p = Post.where(:is_tp => false).last

    post :create, params: { :feedback => { :message_link => "foo", :user_name => "Undo", :user_link => "http://foo.bar/undo", :feedback_type => "tpu-", :post_link => p.link, :chat_user => 12345 }, :key => SmokeDetector.last.access_token }

    assert Post.find(p.id).is_tp

    p = Post.where(:is_fp => false).last

    post :create, params: { :feedback => { :message_link => "foo", :user_name => "Undo", :user_link => "http://foo.bar/undo", :feedback_type => "fpu-", :post_link => p.link, :chat_user => 12345 }, :key => SmokeDetector.last.access_token }

    assert Post.find(p.id).is_fp
  end
end
