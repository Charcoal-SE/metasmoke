require 'test_helper'

class StatusControllerTest < ActionController::TestCase
  def setup
    @smoke_detector = SmokeDetector.order(:last_ping).last
  end

  test "should get index" do
    [0, 2, 10].each do |m|
      @smoke_detector.update(:last_ping => m.minutes.ago)
      get :index
      assert_response :success
    end
  end

  test "should update last-seen time on status ping" do
    old_ping_time = @smoke_detector.last_ping
    post :status_update, params: { :key => @smoke_detector.access_token, :location => @smoke_detector.location}
    assert_in_delta Time.now.to_i, @smoke_detector.reload.last_ping.to_i, 2
  end

  test "should failover" do
    SmokeDetector.update_all(is_standby: true)

    post :status_update, params: { :key => @smoke_detector.access_token, :location => @smoke_detector.location}
    assert_equal false, @smoke_detector.is_standby
  end
end
