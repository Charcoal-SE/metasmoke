class AddAddedByToPostsSpamDomains < ActiveRecord::Migration[5.2]
  def change
    add_reference :posts_spam_domains, :added_by, foreign_key: { to_table: :users }
  end
end
