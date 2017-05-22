# frozen_string_literal: true

class Reason < ApplicationRecord
  has_and_belongs_to_many :posts
  has_many :feedbacks, through: :posts

  def tp_percentage
    # I don't like the .count.count, but it does get the job done

    count = posts.where(is_tp: true, is_fp: false).count

    (count.to_f / fast_post_count.to_f).to_f
  end

  def fp_percentage
    count = posts.where(is_fp: true, is_tp: false).count

    (count.to_f / fast_post_count.to_f).to_f
  end

  def both_percentage
    count = posts.where(is_fp: true, is_tp: true).count
    count += posts.includes(:feedbacks)
                  .where(is_tp: false, is_fp: false)
                  .where.not(feedbacks: { post_id: nil }).count

    (count.to_f / fast_post_count.to_f).to_f
  end

  # Attempt to use cached post_count if it's available (included in the dashboard/index query)
  def fast_post_count
    try(:post_count) || posts.count
  end
end
