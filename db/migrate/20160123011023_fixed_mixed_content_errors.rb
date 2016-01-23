class FixedMixedContentErrors < ActiveRecord::Migration
  def change
    Site.all.each do |site|
      site.site_logo.gsub!(/http:/, "")
      site.save!
    end
  end
end
