require 'test_helper'

class RedisLogControllerTest < ActionDispatch::IntegrationTest
  test "should get user" do
    get redis_log_user_url
    assert_response :success
  end

  test "should get index" do
    get redis_log_index_url
    assert_response :success
  end

  test "should get session" do
    get redis_log_session_url
    assert_response :success
  end

  test "should get status" do
    get redis_log_status_url
    assert_response :success
  end

end
