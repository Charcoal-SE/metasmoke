# frozen_string_literal: true

class RetroactivelySetSiteIdOnFlagLog < ActiveRecord::Migration[5.0]
  def change
    FlagLog.joins(:post).update_all('flag_logs.site_id = posts.site_id')
  end
end
