# frozen_string_literal: true

class CommentScrubber < Rails::Html::PermitScrubber
  def initialize
    super
    self.tags = %w[a p b i em strong hr h1 h2 h3 h4 h5 h6 blockquote img strike del code pre br ul ol li]
    self.attributes = %w[href title src height width]
  end

  def skip_node?(node)
    node.text?
  end
end

class PostComment < ApplicationRecord
  include Websocket

  belongs_to :post
  belongs_to :user

  before_create :remove_feedbacks

  def self.scrubber
    CommentScrubber.new
  end

  def remove_feedbacks
    _feedback_type, comment = text.scan(/(fp|tp|why)?\W*(.*)/i).flatten
    self.text = comment.to_s
  end
end
