require 'test_helper'

class ApiControllerTest < ActionController::TestCase
  test "shouldn't allow unauthenticated users to write" do
    sign_out(:users)
    put :create_feedback, params: { id: 23653, type: 'tpu-', key: api_keys(:one).key }
    json = JSON.parse(@response.body)
    assert_response(401)
    assert_equal 401, json['error_code']
    assert_equal 'unauthorized', json['error_name']
  end

  test "should return created and post feedback" do
    sign_in users(:admin_user)
    put :create_feedback, params: { id: 23653, type: 'tpu-', key: api_keys(:one).key, token: api_tokens(:one).token }
    assert_nothing_raised do
      JSON.parse(@response.body)
    end
    assert_response(201)
  end

  test "should associate feedback with API key" do
    sign_in users(:admin_user)

    assert_difference ApiKey.find(api_keys(:one).id).feedbacks do
      post :create_feedback, params: { id: 23653, type: 'tpu-', key: api_keys(:one).key, token: api_tokens(:one).token }
      assert_nothing_raised do
        JSON.parse(@response.body)
      end
      assert_response(201)
    end
  end

  # This also happens to test that feedback is actually
  # *created*, since expects delta=1
  test "should prevent duplicate feedback from api" do
    sign_in users(:admin_user)

    assert_difference 'Feedback.count' do # delta of one
      2.times do
        post :create_feedback, params: { id: 23653, type: "tpu-", key: api_keys(:one).key, token: api_tokens(:one).token }
      end
    end
  end

  test "should get posts by feedback" do
    get :posts_by_feedback, params: { type: Feedback.first.feedback_type, key: api_keys(:one).key }

    assert_response :success
    assert assigns(:posts).to_a.count > 0
    assert assigns(:posts).select { |p| p.feedbacks.where(:feedback_type => Feedback.first.feedback_type).exists? }.count == assigns(:posts).to_a.count
  end

  test "should get post by URL" do
    get :posts_by_url, params: { url: Post.last.link, key: api_keys(:one).key }

    assert_response :success
    assert assigns(:post).exists?
    assert assigns(:post).select { |p| p.link == Post.last.link }.count == assigns(:post).count
  end

  test "should get posts by site" do
    get :posts_by_site, params: { site: Post.last.site.site_domain, key: api_keys(:one).key }

    assert_response :success
    assert assigns(:posts).to_a.count > 0
    assert assigns(:posts).select { |p| p.site.site_domain == Post.last.site.site_domain }.count == assigns(:posts).to_a.count
  end

  # Search tests

  test "should search for everything" do
    get :search_posts, params: { key: api_keys(:one).key }

    assert_response :success
    assert assigns(@posts).count > 0
  end

  test "should search by feedback type" do
    get :search_posts, params: { feedback_type: Feedback.first.feedback_type, key: api_keys(:one).key }

    assert_response :success
    assert assigns(:posts).count > 0
    assert assigns(:posts).select { |p| p.feedbacks.where(:feedback_type => Feedback.first.feedback_type).exists? }.count == assigns(:posts).count
  end

  test "should search within site" do
    get :search_posts, params: { site: Post.last.site.site_domain, key: api_keys(:one).key }

    assert_response :success
    assert assigns(:posts).count > 0
    assert assigns(:posts).select { |p| p.site.site_domain == Post.last.site.site_domain }.count == assigns(:posts).count
  end

  test "should search by date" do
    get :search_posts, params: { from_date: (Post.last.created_at - 1.second).to_i, key: api_keys(:one).key }

    assert_response :success
    assert assigns(:posts).count > 0
    assert assigns(:posts).select { |p| p.created_at >= Post.last.created_at - 1.second }.count == assigns(:posts).count

    get :search_posts, params: { to_date: (Post.last(2).first.created_at + 1.second).to_i, key: api_keys(:one).key }

    assert_response :success
    assert assigns(:posts).count > 0
    assert assigns(:posts).select { |p| p.created_at <= Post.last(2).first.created_at + 1.second }.count == assigns(:posts).count
  end
end
