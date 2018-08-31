# frozen_string_literal: true

class CreateDomainLinks < ActiveRecord::Migration[5.2]
  def change
    create_table :domain_links do |t|
      t.bigint :left_id
      t.bigint :right_id
      t.string :link_type
      t.text :comments
      t.bigint :creator_id

      t.timestamps
    end

    add_foreign_key :domain_links, :spam_domains, column: :left_id
    add_foreign_key :domain_links, :spam_domains, column: :right_id
    add_foreign_key :domain_links, :users, column: :creator_id
    add_index :domain_links, :left_id
    add_index :domain_links, :right_id
    add_index :domain_links, :creator_id
  end
end
