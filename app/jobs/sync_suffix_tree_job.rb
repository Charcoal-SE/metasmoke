# frozen_string_literal: true

class SyncSuffixTreeJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Job started (#{DateTime.now}, +0s)"
    if SuffixTreeHelper.functional?
      SuffixTreeHelper.sync!
    else
      Rails.logger.warn "Suffix tree not functional; reason: #{SuffixTreeHelper.broken_reason}. Not performing msync."
    end
    Rails.logger.info "Job finished (#{DateTime.now})"
  end
end
