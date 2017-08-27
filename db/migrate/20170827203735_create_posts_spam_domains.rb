# frozen_string_literal: true

class CreatePostsSpamDomains < ActiveRecord::Migration[5.1]
  def change
    create_table :posts_spam_domains, id: false do |t|
      t.integer :post_id
      t.integer :spam_domain_id
    end

    execute 'ALTER TABLE posts_spam_domains ADD PRIMARY KEY (post_id, spam_domain_id);'
  end
end
