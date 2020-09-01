# frozen_string_literal: true

class SyncSuffixTreeJob < ApplicationJob
  queue_as :default

  def perform
    if SuffixTreeHelper.functional?
      SuffixTreeHelper.sync!
    else
      Rails.logger.warn "Suffix tree not functional; reason: #{SuffixTreeHelper.broken_reason}. Not performing msync."
    end
  end
end
