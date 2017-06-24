# frozen_string_literal: true

module ApplicationHelper
  def title(text)
    content_for :title, text
    text
  end

  def active(clazz, action = nil)
    return '' unless controller.class == clazz
    if action
      return controller.action_name == action.to_s ? 'active' : ''
    end
    'active'
  end
end
