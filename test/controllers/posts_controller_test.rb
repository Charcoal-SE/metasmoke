require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def setup
    sign_in User.first
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:posts)
  end
end
