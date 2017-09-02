# frozen_string_literal: true

class CreateSpamDomains < ActiveRecord::Migration[5.1]
  def change
    create_table :spam_domains do |t|
      t.string :domain
      t.text :whois

      t.timestamps
    end
  end
end
