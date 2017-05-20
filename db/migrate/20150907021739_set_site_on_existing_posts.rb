# frozen_string_literal: true

class SetSiteOnExistingPosts < ActiveRecord::Migration[4.2]
  def change
    Post.all.each do |post|
      next if post.link.nil?

      post.site = Site.find_by_site_domain(URI.parse(post.link).host)
      post.save!
    end
  end
end
