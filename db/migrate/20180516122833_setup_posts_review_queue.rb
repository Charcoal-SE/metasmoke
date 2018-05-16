# frozen_string_literal: true

class SetupPostsReviewQueue < ActiveRecord::Migration[5.2]
  def change
    ReviewQueue.create name: 'posts', privileges: 'reviewer', responses: [['True Positive', 'tp'], ['False Positive', 'fp'], %w[NAA naa]]
  end
end
