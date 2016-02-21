class SmokeDetector < ActiveRecord::Base
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
end
