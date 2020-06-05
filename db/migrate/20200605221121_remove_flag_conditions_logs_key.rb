class RemoveFlagConditionsLogsKey < ActiveRecord::Migration[5.2]
  def change
    remove_foreign_key :flag_logs, :flag_conditions
  end
end
