# frozen_string_literal: true

class AddAPIParameterToSites < ActiveRecord::Migration[5.2]
  def change
    add_column :sites, :api_parameter, :string
  end
end
