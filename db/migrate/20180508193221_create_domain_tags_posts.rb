# frozen_string_literal: true

class CreateDomainTagsPosts < ActiveRecord::Migration[5.2]
  def change
    create_table :domain_tags_posts, id: false do |t|
      t.bigint :domain_tag_id, null: false
      t.bigint :post_id, null: false
    end

    execute 'ALTER TABLE domain_tags_posts ADD PRIMARY KEY (domain_tag_id, post_id);'
  end
end
