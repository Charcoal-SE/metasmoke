class SmokeDetector < ApplicationRecord
  belongs_to :user

  def self.status_color
    SmokeDetector.select("last_ping").order("last_ping DESC").first.status_color
  end

  def status_color
    if last_ping > 90.seconds.ago
      return "good"
    elsif last_ping >= 3.minutes.ago
      return "warning"
    elsif last_ping < 3.minutes.ago
      return "critical"
    end
  end

  def self.check_smokey_status
    smoke_detector = SmokeDetector.order("last_ping DESC").first

    if smoke_detector.last_ping < 3.minutes.ago and (smoke_detector.email_date || 1.week.ago) < smoke_detector.last_ping
      HairOnFireMailer.smokey_down_email(smoke_detector).deliver_now

      smoke_detector.email_date = DateTime.now
      smoke_detector.save!
    end
  end
end
