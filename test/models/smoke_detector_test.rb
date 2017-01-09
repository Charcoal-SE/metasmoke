require 'test_helper'

class SmokeDetectorTest < ActiveSupport::TestCase
  test "should check Smokey status" do
    s = SmokeDetector.order("last_ping DESC").first
    SmokeDetector.check_smokey_status

    assert_not_equal s.email_date, SmokeDetector.order("last_ping DESC").first.email_date
  end
end
