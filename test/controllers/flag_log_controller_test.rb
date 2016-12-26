require 'test_helper'

class FlagLogControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get flag_log_index_url
    assert_response :success
  end

end
