# frozen_string_literal: true

module FeedbacksHelper
  def element_class_for_feedback(f)
    if f.is_negative?
      'text-danger'
    elsif f.is_positive?
      'text-success'
    else
      ''
    end
  end

  def element_symbol_for_feedback(f)
    if f.is_negative?
      '&#x2717;'
    elsif f.is_positive?
      '&#x2713;'
    elsif f.is_naa?
      '&#128169;'
    else
      ''
    end
  end
end
