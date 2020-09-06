# frozen_string_literal: true

class DropTableDumps < ActiveRecord::Migration[5.2]
  execute 'DROP TABLE dumps'
end
