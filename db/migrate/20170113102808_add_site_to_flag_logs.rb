class AddSiteToFlagLogs < ActiveRecord::Migration[5.0]
  def change
    add_reference :flag_logs, :site, foreign_key: true
  end
end
