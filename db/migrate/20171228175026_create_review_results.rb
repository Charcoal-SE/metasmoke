# frozen_string_literal: true

class CreateReviewResults < ActiveRecord::Migration[5.1]
  def change
    create_table :review_results do |t|
      t.references :post, foreign_key: true
      t.references :user, foreign_key: true
      t.references :feedback, foreign_key: true
      t.string :result

      t.timestamps
    end
  end
end
