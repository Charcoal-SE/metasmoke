# frozen_string_literal: true

class ExtractDomainNamesFromPosts < ActiveRecord::Migration[5.1]
  def change
    Post.all.each(&:parse_domains)
  end
end
