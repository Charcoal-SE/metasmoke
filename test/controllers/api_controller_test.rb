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
end
