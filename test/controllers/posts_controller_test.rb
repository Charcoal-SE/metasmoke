require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def setup
    @posts = Post.all
    @single_post = Post.last
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:posts)
  end

  test "should show post" do
    @posts.each do |post|
      get :show, params: { :id => post.id }
      assert_response :success
      assert_not_nil assigns(:post)
    end
  end

  test "should require smokedetector key to create post" do
    post :create, params: { :post => {} }
    assert_response :forbidden

    post :create, params: { :post => {}, :key => "wrongkey" }
    assert_response :forbidden
  end
end
