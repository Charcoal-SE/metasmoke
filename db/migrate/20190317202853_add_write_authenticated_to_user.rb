class AddWriteAuthenticatedToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :write_authenticated, :boolean, null: false, default: false
    rename_column :users, :encrypted_api_token, :encrypted_api_token_legacy
    reversible do |dir|
      dir.up do
        User.where(flags_enabled:true).each do |u|
          u.update(write_authenticated: true)
        end
      end
    end
  end
end
