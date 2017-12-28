class ReviewResult < ApplicationRecord
  belongs_to :post
  belongs_to :user
  belongs_to :feedback, required: false
end
