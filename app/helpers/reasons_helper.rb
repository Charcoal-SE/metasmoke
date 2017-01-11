module ReasonsHelper
  def self.check_for_inactive_reasons
    Reason.where(:inactive => false).each do |reason|
      begin
        if reason.posts.last.created_at < 30.days.ago
          reason.inactive = true
          reason.save!
        end
      rescue
      end
    end
  end

  def self.calculate_weights_for_flagging
    Reason.all.each do |reason|
      reason.update(:weight => reason.tp_percentage * 100)
    end
  end
end
