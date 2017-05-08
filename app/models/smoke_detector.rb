class SmokeDetector < ApplicationRecord
  audited on: [:destroy]

  belongs_to :user
  has_many :statistics
  has_many :posts

  def should_failover
    self.force_failover || (self.is_standby && SmokeDetector.where(is_standby: false).where('last_ping > ?', 3.minutes.ago).empty?)
  end

  def as_json(options = {})
    opts = {
      except: [:access_token],
      methods: [:status_color]
    }
    opts.deep_merge!(options) { |key, a, b|
      if a.instance_of? Array
        a + b
      elsif a.instance_of? Hash then
        a.deep_merge b
      else
        b
      end
    }
    super(opts)
  end

  def self.status_color
    SmokeDetector.select('last_ping').order('last_ping DESC').first.status_color
  end

  def status_color
    if last_ping > 90.seconds.ago
      return 'good'
    elsif last_ping >= 3.minutes.ago
      return 'warning'
    elsif last_ping < 3.minutes.ago
      return 'critical'
    end
  end

  def self.check_smokey_status
    smoke_detector = SmokeDetector.order('last_ping DESC').first

    if smoke_detector.last_ping < 3.minutes.ago and (smoke_detector.email_date || 1.week.ago) < smoke_detector.last_ping
      HairOnFireMailer.smokey_down_email(smoke_detector).deliver_now

      smoke_detector.email_date = DateTime.now
      smoke_detector.save!
    end
  end

  def self.send_message_to_charcoal(message)
    ActionCable.server.broadcast 'smokedetector_messages', { message: message }
  end
end
