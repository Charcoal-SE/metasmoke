# frozen_string_literal: true

class UpdateFeedbackCountsAgain < ActiveRecord::Migration[5.2]
  def change
    counts = Post.left_joins(:feedbacks).group(Arel.sql('posts.id')).count
    count_values = counts.map { |k, v| "(#{k}, #{v})" }.join(', ')
    sql = "INSERT INTO posts (id, feedbacks_count) VALUES #{count_values} ON DUPLICATE KEY UPDATE feedbacks_count = VALUES(feedbacks_count);"
    ActiveRecord::Base.connection.execute sql
  end
end
