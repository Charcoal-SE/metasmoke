require 'test_helper'

class ReasonsControllerTest < ActionController::TestCase
  test "should get reason page" do
    get :show, params: { id: Reason.first }
  end
end
