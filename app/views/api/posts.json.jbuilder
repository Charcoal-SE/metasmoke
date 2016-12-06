json.items(@results) do |post|
  json.merge! post.as_json
  json.merge!({
    :count_tp => post.feedbacks.where('feedbacks.feedback_type LIKE ?', 't%').count,
    :count_fp => post.feedbacks.where('feedbacks.feedback_type LIKE ?', 'f%').count,
    :count_naa => post.feedbacks.where('feedbacks.feedback_type LIKE ?', 'n%').count
  })
end

json.has_more @more
