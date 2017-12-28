# frozen_string_literal: true

class ChangePrimaryKeyTypesWtfMySql < ActiveRecord::Migration[5.1]
  def change
    database = Rails.configuration.database_configuration[Rails.env]['database']
    constraints_query = %{
      select table_name, column_name, constraint_name, referenced_table_name, referenced_column_name
      from information_schema.key_column_usage where referenced_table_name is not null and referenced_column_name is not null and
      constraint_schema = '#{database}' and referenced_table_name in ('posts', 'users', 'feedbacks') and referenced_column_name = 'id';
    }
    constraints_result = ActiveRecord::Base.connection.execute constraints_query
    constraints = constraints_result.to_a

    # Drop foreign keys so we can alter the columns they affect
    constraints.each do |c|
      table = c[0]
      name = c[2]
      ActiveRecord::Base.connection.execute "alter table #{table} drop foreign key #{name}"
    end

    # Change primary key types
    change_column :posts, :id, :bigint, auto_increment: true
    change_column :users, :id, :bigint, auto_increment: true
    change_column :feedbacks, :id, :bigint, auto_increment: true

    # Change referencing column types
    constraints.each do |c|
      table, column = c[0...2]
      change_column table.to_sym, column.to_sym, :bigint
    end

    # Restore foreign keys
    constraints.each do |c|
      table, column, name, ref_table, ref_column = c
      query = "alter table #{table} add constraint #{name} foreign key (#{column}) references #{ref_table}(#{ref_column})"
      ActiveRecord::Base.connection.execute query
    end
  end
end
