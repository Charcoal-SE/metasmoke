# frozen_string_literal: true

class ExtractDomainNamesFromPostsAndTitles < ActiveRecord::Migration[5.1]
  def change
    Post.all.each(&:parse_domains)
  end
end
