class RemoveForeignKeyConstraintForFlagLogs < ActiveRecord::Migration[5.2]
  def change
    remove_foreign_key :flag_logs, name: :fk_rails_d6d60057f2
  end
end
