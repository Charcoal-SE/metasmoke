class FixReasonsWithParenthesis < ActiveRecord::Migration[4.2]
  def change
    Reason.where("reason_name LIKE '%(%'").each do |reason|
      new_reason = Reason.find_or_create_by(reason_name: reason.reason_name.split("(").first.strip.humanize)

      reason.posts.each do |post|
        post.reasons.delete(reason)
        post.reasons << new_reason
        post.save!
      end
    end
  end
end
