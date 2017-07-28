# frozen_string_literal: true

class AnnouncementScrubber < Rails::Html::PermitScrubber
  def initialize
    super
    self.tags = %w[a p b i em strong hr h1 h2 h3 h4 h5 h6 blockquote img strike del code pre br ul ol li]
    self.attributes = %w[href title src height width]
  end

  def skip_node?(node)
    node.text?
  end
end

class Announcement < ApplicationRecord
  def current?
    expiry > DateTime.now
  end

  def self.current
    Announcement.where('expiry > ?', DateTime.now)
  end

  def self.scrubber
    AnnouncementScrubber.new
  end
end
