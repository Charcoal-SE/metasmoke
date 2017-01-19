class HairOnFireMailer < ApplicationMailer
  default from: "Hair on Fire <metasmoke@erwaysoftware.com>"

  def smokey_down_email(smoke_detector)
    @last_ping_date = smoke_detector.last_ping
    @location = smoke_detector.location

    mail(to: smoke_detector.user.email, cc: "teward@ubuntu.com; undo@erwaysoftware.com; hello@artofcode.co.uk", subject: "[SmokeDetector] status DOWN (last seen #{@last_ping_date})")
  end
end
