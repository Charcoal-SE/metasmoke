require 'test_helper'

class StatusControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  test "should get index" do
    get :index
    assert_response :success
  end

  test "should update last-seen time on status ping" do
    old_ping_time = SmokeDetector.last.last_ping
    post :status_update, params: { :key => SmokeDetector.last.access_token, :location => SmokeDetector.last.location}
    assert_in_delta Time.now.to_i, SmokeDetector.last.last_ping.to_i, 2
  end
end
