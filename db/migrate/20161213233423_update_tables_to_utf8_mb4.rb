# frozen_string_literal: true

class UpdateTablesToUtf8Mb4 < ActiveRecord::Migration[5.0]
  def change
    [Post, StackExchangeUser].each do |m|
      execute "ALTER TABLE #{m.table_name} CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
    end

    posts_column_types = Post.columns_hash

    # Post table columns
    execute "ALTER TABLE `posts` MODIFY `title` #{posts_column_types['title'].sql_type} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
    execute "ALTER TABLE `posts` MODIFY `body` #{posts_column_types['body'].sql_type} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
    execute "ALTER TABLE `posts` MODIFY `username` #{posts_column_types['username'].sql_type} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"

    # StackExchangeUser table columns
    # rubocop:disable Layout/LineLength
    execute "ALTER TABLE `stack_exchange_users` MODIFY `username` #{posts_column_types['username'].sql_type} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
    # rubocop:enable Layout/LineLength
  end
end
