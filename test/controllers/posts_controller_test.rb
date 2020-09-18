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
          why: 'Some why data',
          reasons: ['Bad keyword in body']
        },
        key: SmokeDetector.first.access_token
      }

      assert_response :success
    end
  end

  test 'should quietly reject recent duplicates from other instances as 200 Duplicate Report' do
    post :create, params: {
      post: {
        title: 'blah blah blah',
        body: 'blah blah',
        link: '//stackoverflow.com/questions/1234',
        username: 'Undo',
        user_reputation: 101,
        user_link: '//stackoverflow.com/users/123',
        why: 'Some why data',
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
          why: 'Some why data',
          reasons: ['Bad keyword in body']
        },
        key: SmokeDetector.last.access_token
      }

      assert_response(200, 'Duplicate Report')
    end
  end

  test 'should quietly reject duplicate posts from same instance as 200 Duplicate Report' do
    post :create, params: {
      post: {
        title: 'blah blah blah',
        body: 'blah blah',
        link: '//stackoverflow.com/questions/1234',
        username: 'Undo',
        user_reputation: 101,
        user_link: '//stackoverflow.com/users/123',
        why: 'Some why data',
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
          why: 'Some why data',
          reasons: ['Bad keyword in body']
        },
        key: SmokeDetector.first.access_token
      }

      assert_response(200, 'Duplicate Report')
    end
  end

  test 'should not reject near-duplicate posts with different title' do
    post :create, params: {
      post: {
        title: 'blah blah blah',
        body: 'blah blah',
        link: '//stackoverflow.com/questions/1234',
        username: 'Undo',
        user_reputation: 101,
        user_link: '//stackoverflow.com/users/123',
        why: 'Some why data',
        reasons: ['Bad keyword in body']
      },
      key: SmokeDetector.first.access_token
    }

    assert_difference 'Post.count' do
      post :create, params: {
        post: {
          title: 'blah blah diff',
          body: 'blah blah',
          link: '//stackoverflow.com/questions/1234',
          username: 'Undo',
          user_reputation: 101,
          user_link: '//stackoverflow.com/users/123',
          why: 'Some why data',
          reasons: ['Bad keyword in body']
        },
        key: SmokeDetector.first.access_token
      }

      assert_response(201, 'OK')
    end
  end

  test 'should not reject near-duplicate posts with different body' do
    post :create, params: {
      post: {
        title: 'blah blah blah',
        body: 'blah blah',
        link: '//stackoverflow.com/questions/1234',
        username: 'Undo',
        user_reputation: 101,
        user_link: '//stackoverflow.com/users/123',
        why: 'Some why data',
        reasons: ['Bad keyword in body']
      },
      key: SmokeDetector.first.access_token
    }

    assert_difference 'Post.count' do
      post :create, params: {
        post: {
          title: 'blah blah blah',
          body: 'blah diff',
          link: '//stackoverflow.com/questions/1234',
          username: 'Undo',
          user_reputation: 101,
          user_link: '//stackoverflow.com/users/123',
          why: 'Some why data',
          reasons: ['Bad keyword in body']
        },
        key: SmokeDetector.first.access_token
      }

      assert_response(201, 'OK')
    end
  end

  test 'should not reject near-duplicate posts with different username' do
    post :create, params: {
      post: {
        title: 'blah blah blah',
        body: 'blah blah',
        link: '//stackoverflow.com/questions/1234',
        username: 'Redo',
        user_reputation: 101,
        user_link: '//stackoverflow.com/users/123',
        why: 'Some why data',
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
          why: 'Some why data',
          reasons: ['Bad keyword in body']
        },
        key: SmokeDetector.first.access_token
      }

      assert_response(201, 'OK')
    end
  end

  test 'should not reject near-duplicate posts with different why' do
    post :create, params: {
      post: {
        title: 'blah blah blah',
        body: 'blah blah',
        link: '//stackoverflow.com/questions/1234',
        username: 'Undo',
        user_reputation: 101,
        user_link: '//stackoverflow.com/users/123',
        why: 'Some why data',
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
          why: 'Some why diff',
          reasons: ['Bad keyword in body']
        },
        key: SmokeDetector.first.access_token
      }

      assert_response(201, 'OK')
    end
  end

  test 'should not reject near-duplicate posts with different link' do
    post :create, params: {
      post: {
        title: 'blah blah blah',
        body: 'blah blah',
        link: '//stackoverflow.com/questions/1234',
        username: 'Undo',
        user_reputation: 101,
        user_link: '//stackoverflow.com/users/123',
        why: 'Some why data',
        reasons: ['Bad keyword in body']
      },
      key: SmokeDetector.first.access_token
    }

    assert_difference 'Post.count' do
      post :create, params: {
        post: {
          title: 'blah blah blah',
          body: 'blah blah',
          link: '//stackoverflow.com/questions/1235',
          username: 'Undo',
          user_reputation: 101,
          user_link: '//stackoverflow.com/users/123',
          why: 'Some why data',
          reasons: ['Bad keyword in body']
        },
        key: SmokeDetector.first.access_token
      }

      assert_response(201, 'OK')
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

      assert_response :success
    end
  end

  test 'should lazy-load post body' do
    get :body, params: { id: Post.last.id }
    assert_response 200
    assert assigns(:post)
  end
end
