# frozen_string_literal: true

class MigrateToCachedDeletionTimes < ActiveRecord::Migration[5.0]
  def change
    sql = <<-SQL
      UPDATE `posts`
      INNER JOIN
        (SELECT `deletion_logs`.`post_id`, min(`deletion_logs`.`created_at`) as min_dl FROM `deletion_logs` WHERE `is_deleted` = true GROUP BY `deletion_logs`.`post_id`) dl on dl.post_id = posts.id
      SET `posts`.`deleted_at` = dl.min_dl
    SQL

    ActiveRecord::Base.connection.execute(sql)
  end
end
