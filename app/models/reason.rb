# frozen_string_literal: true

class Reason < ApplicationRecord
  include Websocket

  has_and_belongs_to_many :posts
  has_many :feedbacks, through: :posts

  def self.populate_redis_meta
    redis.pipelined do
      find_each do |reason|
        redis.sadd 'reasons', reason.id
        reason.posts.select(:id).each do |post|
          redis.sadd "reasons/#{reason.id}", post.id
        end
      end
    end
  end

  def tp_percentage
    # I don't like the .count.count, but it does get the job done

    count = posts.where(is_tp: true, is_fp: false).count

    count.to_f / posts.count
  end

  def fp_percentage
    count = posts.where(is_fp: true, is_tp: false).count

    count.to_f / posts.count
  end

  def both_percentage
    count = posts.where(is_fp: true, is_tp: true).count
    count += posts.includes(:feedbacks)
                  .where(is_tp: false, is_fp: false)
                  .where.not(feedbacks: { post_id: nil }).count

    count.to_f / posts.count
  end
end
