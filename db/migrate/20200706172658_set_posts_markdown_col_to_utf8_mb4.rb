class SetPostsMarkdownColToUtf8Mb4 < ActiveRecord::Migration[5.2]
  def change
    execute "ALTER TABLE `posts` MODIFY `markdown` mediumtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
  end
end
