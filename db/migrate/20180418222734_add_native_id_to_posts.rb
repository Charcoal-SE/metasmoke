# frozen_string_literal: true

class AddNativeIdToPosts < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :native_id, :bigint

    native_ids = Post.where.not(link: nil).map do |p|
      match = /\/(?:q(?:uestions)?|a(?:nswers)?)\/(\d+)/.match(p.link)
      if match
        [p.id, match[1]]
      end.compact
    end
    native_id_values = native_ids.map { |n| "(#{n[0]}, #{n[1]})" }.join(', ')
    sql = "INSERT INTO posts (id, native_id) VALUES #{native_id_values} ON DUPLICATE KEY UPDATE native_id = VALUES(native_id);"

    ActiveRecord::Base.connection.execute sql
  end
end
