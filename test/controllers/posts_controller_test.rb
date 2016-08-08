require 'test_helper'

class PostsControllerTest < ActionController::TestCase
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

  test "should create post" do
    assert_difference 'Post.count' do
      post :create, params: { :post => { :title => "Test Post Title", :body => "Awesome Post Body", :link => "//stackoverflow.com/q/1", :username => "Undo", :user_reputation => 101, :user_link => "//stackoverflow.com/users/1849664/undo", :reasons => ["Bad keyword in body"] }, :key => SmokeDetector.first.access_token }
    end
  end

  test "should create new reason" do
    assert_difference 'Reason.count' do
      post :create, params: { :post => { :title => "Test Post Title", :body => "Awesome Post Body", :link => "//stackoverflow.com/q/1", :username => "Undo", :user_reputation => 101, :user_link => "//stackoverflow.com/users/1849664/undo", :reasons => ["Brand new reason"] }, :key => SmokeDetector.first.access_token }
    end
  end
end
