# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # From http://stackoverflow.com/questions/6591722/how-to-generate-fixtures-based-on-my-development-database
  def dump_fixture
    fixture_file = "#{Rails.root}/test/fixtures/#{self.class.table_name}.yml"
    File.open(fixture_file, 'a') do |f|
      f.puts({ "#{self.class.table_name.singularize}_#{id}" => attributes }
        .to_yaml.sub!(/---\s?/, "\n"))
    end
  end

  def self.sanitize_like(unsafe, *args)
    sanitize_sql_like unsafe, *args
  end

  def self.mass_habtm(join_table, first_type, second_type, record_pairs)
    record_ids = record_pairs.map { |p| p[0..1].map(&:id) }
    values = record_ids.map { |p| "(#{p[0]}, #{p[1]})" }.join(', ')
    query = "INSERT INTO #{join_table} (#{first_type}_id, #{second_type}_id) VALUES #{values};"
    transaction do
      connection.execute query
    end
  end
end
