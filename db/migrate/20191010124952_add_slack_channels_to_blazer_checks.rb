class AddSlackChannelsToBlazerChecks < ActiveRecord::Migration[5.2]
  def change
    add_column :blazer_checks, :slack_channels, :text
  end
end
