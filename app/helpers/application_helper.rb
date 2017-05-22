# frozen_string_literal: true

module ApplicationHelper
  def title(text)
    content_for :title, text
    text
  end
end
