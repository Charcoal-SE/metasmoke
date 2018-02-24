# frozen_string_literal: true

require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  def setup
    @posts = Post.all
    @single_post = Post.last
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:posts)
  end

  test 'should show post' do
    @posts.each do |post|
      get :show, params: { id: post.id }
      assert_response :success
      assert_not_nil assigns(:post)
    end
  end

  test 'should show posts to signed-in users' do
    sign_in users(:admin_user)
    @posts.each do |post|
      get :show, params: { id: post.id }
      assert_response :success
      assert_not_nil assigns(:post)
    end
  end

  test 'should require smokedetector key to create post' do
    post :create, params: { post: {} }
    assert_response :forbidden

    post :create, params: { post: {}, key: 'wrongkey' }
    assert_response :forbidden
  end

  test 'should create post' do
    assert_difference 'Post.count' do
      post :create, params: {
        post: {
          title: 'Test Post Title',
          body: 'Awesome Post Body',
          link: '//stackoverflow.com/questions/1',
          username: 'Undo',
          user_reputation: 101,
          user_link: '//stackoverflow.com/users/1849664/undo',
          reasons: ['Bad keyword in body']
        },
        key: SmokeDetector.first.access_token
      }
    end
  end

  test 'should reject recent duplicates from other instances' do
    post :create, params: {
      post: {
        title: 'blah blah blah',
        body: 'blah blah',
        link: '//stackoverflow.com/questions/1234',
        username: 'Undo',
        user_reputation: 101,
        user_link: '//stackoverflow.com/users/123',
        reasons: ['Bad keyword in body']
      },
      key: SmokeDetector.first.access_token
    }

    assert_no_difference 'Post.count' do
      post :create, params: {
        post: {
          title: 'blah blah blah',
          body: 'blah blah',
          link: '//stackoverflow.com/questions/1234',
          username: 'Undo',
          user_reputation: 101,
          user_link: '//stackoverflow.com/users/123',
          reasons: ['Bad keyword in body']
        },
        key: SmokeDetector.last.access_token
      }

      assert_response :unprocessable_entity
    end
  end

  test 'should not reject duplicate posts from same instance' do
    post :create, params: {
      post: {
        title: 'blah blah blah',
        body: 'blah blah',
        link: '//stackoverflow.com/questions/1234',
        username: 'Undo',
        user_reputation: 101,
        user_link: '//stackoverflow.com/users/123',
        reasons: ['Bad keyword in body']
      },
      key: SmokeDetector.first.access_token
    }

    assert_difference 'Post.count' do
      post :create, params: {
        post: {
          title: 'blah blah blah',
          body: 'blah blah',
          link: '//stackoverflow.com/questions/1234',
          username: 'Undo',
          user_reputation: 101,
          user_link: '//stackoverflow.com/users/123',
          reasons: ['Bad keyword in body']
        },
        key: SmokeDetector.first.access_token
      }
    end
  end

  test 'should create new reason' do
    assert_difference 'Reason.count' do
      post :create, params: {
        post: {
          title: 'Test Post Title',
          body: 'Awesome Post Body',
          link: '//stackoverflow.com/questions/1',
          username: 'Undo',
          user_reputation: 101,
          user_link: '//stackoverflow.com/users/1849664/undo',
          reasons: ['Brand new reason']
        },
        key: SmokeDetector.first.access_token
      }
    end
  end

  test 'should lazy-load post body' do
    get :body, params: { id: Post.last.id }
    assert_response 200
    assert assigns(:post)
  end
end
