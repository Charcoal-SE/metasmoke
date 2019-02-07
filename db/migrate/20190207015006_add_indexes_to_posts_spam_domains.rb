class AddIndexesToPostsSpamDomains < ActiveRecord::Migration[5.2]
  def change
    add_index :posts_spam_domains, :post_id
    add_index :posts_spam_domains, :spam_domain_id
  end
end
