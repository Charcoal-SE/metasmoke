require 'test_helper'

class StatusControllerTest < ActionController::TestCase
  test "should get index" do
    [0, 2, 10].each do |m|
      SmokeDetector.order(:last_ping).last.update(:last_ping => m.minutes.ago)
      get :index
      assert_response :success
    end
  end

  test "should update last-seen time on status ping" do
    old_ping_time = SmokeDetector.last.last_ping
    post :status_update, params: { :key => SmokeDetector.last.access_token, :location => SmokeDetector.last.location}
    assert_in_delta Time.now.to_i, SmokeDetector.last.last_ping.to_i, 2
  end
end
