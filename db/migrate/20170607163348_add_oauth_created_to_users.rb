# frozen_string_literal: true

class AddOauthCreatedToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :oauth_created, :boolean

    User.all.each do |u|
      u.update(oauth_created: true) if /\d+@se-oauth\.metasmoke/.match? u.email
    end
  end
end
