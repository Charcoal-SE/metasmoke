# frozen_string_literal: true

class RerunPostFeedbackCacheFix < ActiveRecord::Migration[5.0]
  def change
    require "#{Rails.root}/db/migrate/20160402185509_retroactively_fix_post_feedback_cache.rb"
    RetroactivelyFixPostFeedbackCache.new.change
  end
end
