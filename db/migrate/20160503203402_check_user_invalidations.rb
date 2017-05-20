class CheckUserInvalidations < ActiveRecord::Migration[5.0]
  def change
    Feedback.pluck(:user_name).uniq.each do |username|
      total_count = Feedback.unscoped.where(user_name: username).count
      invalid_count = Feedback.unscoped.where(user_name: username, is_invalidated: true).count
      next unless invalid_count > (0.04 * total_count) + 4
      ignored = IgnoredUser.new
      ignored.user_name = username
      ignored.is_ignored = true
      ignored.save
    end
  end
end
