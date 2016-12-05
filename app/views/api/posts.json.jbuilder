json.items(@results) do |post|
  json.title post.title
  json.body post.body
  json.link post.link
  json.post_creation_date post.post_creation_date
  json.site_id post.site_id
  json.user_link post.user_link
  json.username post.username
  json.user_reputation post.user_reputation
  json.why post.why
  json.score post.score
  json.stack_exchange_user_id post.stack_exchange_user_id
  json.is_tp post.is_tp
  json.is_fp post.is_fp
  json.count_tp post.feedbacks.where('feedbacks.feedback_type LIKE ?', 't%').count
  json.count_fp post.feedbacks.where('feedbacks.feedback_type LIKE ?', 'f%').count
  json.count_naa post.feedbacks.where('feedbacks.feedback_type LIKE ?', 'n%').count
end

json.has_more @more
