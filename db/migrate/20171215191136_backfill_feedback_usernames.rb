class BackfillFeedbackUsernames < ActiveRecord::Migration[5.1]
  class Feedback < ApplicationRecord
  end
  class User < ApplicationRecord
  end

  def change
    users = User.all.map { |u| [u.id, u.username] }.to_h
    Feedback.where(user_name: nil).where.not(user_id: nil).each do |f|
      f.update(user_name: users[f.user_id])
    end
  end
end
