require 'test_helper'

class DeletionLogsControllerTest < ActionDispatch::IntegrationTest
  test "should require smokedetector key to create deletion log" do
    post '/deletion_logs.json', params: { :post => {} }
    assert_response :forbidden

    post '/deletion_logs.json', params: { :post => {}, :key => "wrongkey" }
    assert_response :forbidden
  end

  test "should create deletion log" do
    assert_difference ['DeletionLog.count', 'Post.last.deletion_logs.count'] do
      post '/deletion_logs.json', params: { :deletion_log => { :is_deleted => true, :post_link => Post.last.link }, :key => SmokeDetector.first.access_token }
    end
  end
end
