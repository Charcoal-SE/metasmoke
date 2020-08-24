# frozen_string_literal: true

class SyncSuffixTreeJob < ApplicationJob
  queue_as :default

  def perform
    SuffixTreeHelper.sync!
  end
end
