# frozen_string_literal: true

class AddDescriptionToPostsReviewQueue < ActiveRecord::Migration[5.2]
  def change
    ReviewQueue['posts'].update(description: 'Review new reports as they come in and add feedback to them.')
  end
end
