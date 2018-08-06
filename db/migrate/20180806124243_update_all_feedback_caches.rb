# frozen_string_literal: true

class UpdateAllFeedbackCaches < ActiveRecord::Migration[5.2]
  def change
    Post.all.each do |post|
      post.update(link: post.link.scan(%r{.*(\/\/(.*?)\/(questions|a)\/\d+).*})[0]) unless post.valid?
      post.update_feedback_cache
    end
  end
end
