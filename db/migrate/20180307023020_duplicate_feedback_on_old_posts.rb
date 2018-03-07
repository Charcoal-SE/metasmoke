# frozen_string_literal: true

class DuplicateFeedbackOnOldPosts < ActiveRecord::Migration[5.2]
  def change
    ActiveRecord::Base.connection.execute 'INSERT INTO feedbacks (user_name, feedback_type, post_id, user_id) '\
                                          "SELECT 'System' AS 'user_name', feedbacks.feedback_type, feedbacks.post_id, -1 AS 'user_id' "\
                                          'FROM feedbacks INNER JOIN posts ON feedbacks.post_id = posts.id WHERE posts.feedbacks_count = 1;'
  end
end
