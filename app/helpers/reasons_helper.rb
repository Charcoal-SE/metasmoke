module ReasonsHelper
  def self.check_for_inactive_reasons
    Reason.where(:inactive => false).each do |reason|
      if reason.posts.last.created_at < 30.days.ago
        reason.inactive = true
        reason.save!
      end
    end
  end
end
