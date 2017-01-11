class SetDefaultValueOnFlagConditionEnabled < ActiveRecord::Migration[5.0]
  def up
    change_column :flag_conditions, :flags_enabled, :boolean, :default => true

    FlagCondition.where(:flags_enabled => nil).update_all(:flags_enabled => true)
  end

  def down
    change_column :flag_conditions, :flags_enabled, :boolean, :default => true
  end
end
