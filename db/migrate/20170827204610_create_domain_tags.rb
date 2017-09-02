# frozen_string_literal: true

class CreateDomainTags < ActiveRecord::Migration[5.1]
  def change
    create_table :domain_tags do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
