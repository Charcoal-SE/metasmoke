# frozen_string_literal: true

class CancelOldUntaggedReviews < ActiveRecord::Migration[5.2]
  def change
    # We're not getting them done and it's negatively affecting review speed in other queues, sooo... yup.
    ReviewQueue['untagged-domains']&.items.update_all(completed: true)
  end
end
