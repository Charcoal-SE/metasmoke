class ConvertFlagLogErrorMessageToText < ActiveRecord::Migration[5.0]
  def up
    change_column :flag_logs, :error_message, :text
  end
  def down
    change_column :flag_logs, :error_message, :string
  end
end
