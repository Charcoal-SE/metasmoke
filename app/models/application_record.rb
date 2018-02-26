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
    first_ids = record_pairs.map { |p| p[0].id }.join(', ')
    second_ids = record_pairs.map { |p| p[1].id }.join(', ')
    pre_existing = connection.execute("SELECT #{first_type}_id, #{second_type}_id FROM #{join_table} " \
                                      "WHERE #{first_type}_id IN (#{first_ids}) AND #{second_type}_id IN (#{second_ids})").to_a

    record_ids = record_pairs.map do |pair|
      pair_ids = [pair[0].id, pair[1].id]
      pre_existing.include?(pair_ids) ? nil : pair_ids
    end.compact

    values = record_ids.map { |p| "(#{p[0]}, #{p[1]})" }.join(', ')
    query = "INSERT INTO #{join_table} (#{first_type}_id, #{second_type}_id) VALUES #{values};"
    connection.execute query
  end

  def self.fields(*names)
    names.map { |n| "#{table_name}.#{n}" }
  end

  def self.full_dump
    `#{Rails.root}/dump/dump.sh`
  end
end
