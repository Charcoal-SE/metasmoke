# frozen_string_literal: true

class CreateDomainTagsSpamDomains < ActiveRecord::Migration[5.1]
  def change
    create_table :domain_tags_spam_domains, id: false do |t|
      t.integer :domain_tag_id
      t.integer :spam_domain_id
    end

    execute 'ALTER TABLE domain_tags_spam_domains ADD PRIMARY KEY (domain_tag_id, spam_domain_id);'
  end
end
