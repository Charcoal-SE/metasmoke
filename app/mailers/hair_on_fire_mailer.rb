class HairOnFireMailer < ApplicationMailer
  default from: "Hair on Fire <metasmoke@erwaysoftware.com>"

  def smokey_down_email(smoke_detector)
    @last_ping_date = smoke_detector.last_ping
    @location = smoke_detector.location

    mail(to: "undo@erwaysoftware.com", subject: "[SmokeDetector] status DOWN (last seen #{@last_ping_date})")
  end
end
