# frozen_string_literal: true

module ReasonsHelper
  def self.check_for_inactive_reasons
    Reason.where(inactive: false).each do |reason|
      begin
        if reason.posts.last.created_at < 30.days.ago
          reason.inactive = true
          reason.save!
        end
      rescue # rubocop:disable Lint/HandleExceptions
      end
    end
  end

  def self.calculate_weights_for_flagging
    Reason.all.each do |reason|
      if reason.posts.count > 20
        reason.update(weight: [(reason.tp_percentage * 100).round, reason.maximum_weight].compact.min)
      else
        reason.update(weight: 0)
      end
    end
  end
end
