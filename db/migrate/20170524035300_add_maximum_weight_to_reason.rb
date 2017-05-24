# frozen_string_literal: true

class AddMaximumWeightToReason < ActiveRecord::Migration[5.1]
  def change
    add_column :reasons, :maximum_weight, :tinyint, default: nil
  end
end
