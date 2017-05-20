# frozen_string_literal: true

class AddInactiveToReasons < ActiveRecord::Migration[5.0]
  def change
    add_column :reasons, :inactive, :boolean, default: false
  end
end
