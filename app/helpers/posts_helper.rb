# frozen_string_literal: true

module PostsHelper
  def render_links(text)
    raw(text.split(%r{((?:https?:)?\/{2}[^\)\s]*)}).map.with_index do |s, i|
      i % 2 == 0 ? s : link_to(s, s)
    end.join)
  end
end
