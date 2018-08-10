# frozen_string_literal: true

class AddAdminFlagsReviewQueue < ActiveRecord::Migration[5.2]
  def change
    q = ReviewQueue.create name: 'admin-flags', privileges: 'admin', responses: [%w[Dismiss dismiss]],
                           description: 'Review "needs admin attention" flags from users on metasmoke posts.'
    Flag.where.not(is_completed: true).each do |f|
      ReviewItem.create queue: q, reviewable: f, completed: false
    end
  end
end
