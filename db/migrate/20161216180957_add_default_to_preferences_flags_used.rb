# frozen_string_literal: true

class AddDefaultToPreferencesFlagsUsed < ActiveRecord::Migration[5.0]
  def change
    change_column :user_site_settings, :flags_used, :integer, default: 0
  end
end
