class AddOauthCreatedToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :oauth_created, :boolean

    User.all.each do |u|
      if %r{\d+@se-oauth\.metasmoke}.match? u.email
        u.update(oauth_created: true)
      end
    end
  end
end
