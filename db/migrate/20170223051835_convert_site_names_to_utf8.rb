class ConvertSiteNamesToUtf8 < ActiveRecord::Migration[5.0]
  def up
    execute 'ALTER TABLE `sites` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_bin'

    SitesHelper.updateSites
  end

  def down; end
end
