# frozen_string_literal: true

class CreateFlagConditionsSitesJoinTable < ActiveRecord::Migration[5.0]
  def change
    create_table 'flag_conditions_sites' do |t|
      t.integer :flag_condition_id
      t.integer :site_id
    end
  end
end
