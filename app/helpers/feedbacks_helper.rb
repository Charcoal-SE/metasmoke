module FeedbacksHelper
  def element_class_for_feedback(f)
    case
    when f.is_negative?
        "text-danger"
      when f.is_positive?
        "text-success"
      else
        ""
    end
  end

  def element_symbol_for_feedback(f)
    case
    when f.is_negative?
        "&#x2717;"
      when f.is_positive?
        "&#x2713;"
      when f.is_naa?
        "&#128169;"
      else
        ""
    end
  end
end
