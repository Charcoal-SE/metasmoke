class ExtractDomainNamesFromPosts < ActiveRecord::Migration[5.1]
  def change
    Post.all.each do |p|
      p.parse_domains
    end
  end
end
