# frozen_string_literal: true

class ReviewResult < ApplicationRecord
  belongs_to :post
  belongs_to :user
  belongs_to :feedback, required: false

  def text_class
    # rubocop:disable Style/NestedTernaryOperator
    # rubocop:disable Style/MultilineTernaryOperator
    result.start_with?('t') ? 'text-success' :
      result.start_with?('f') ? 'text-danger' :
        result.start_with?('n') ? 'text-warning' : 'text-info'
  end
end
