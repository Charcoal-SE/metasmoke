require 'test_helper'

class CodeStatusControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get code_status_index_url
    assert_response :success
  end

end
