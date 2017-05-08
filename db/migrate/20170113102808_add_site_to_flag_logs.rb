class AddSiteToFlagLogs < ActiveRecord::Migration[5.0]
  def change
    add_reference :flag_logs, :site, foreign_key: true

    FlagLog.all.each do |fl|
      fl.update(site: fl.post.site)
    end
  end
end
