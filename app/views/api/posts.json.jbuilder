json.items(@results) do |post|
  json.merge! post.as_json
  json.merge!({
    :count_tp => post.feedbacks.to_a.count { |f| f.feedback_type.include? "t" },
    :count_fp => post.feedbacks.to_a.count { |f| f.feedback_type.include? "f" },
    :count_naa => post.feedbacks.to_a.count { |f| f.feedback_type.include? "n" },
    :autoflagged => {
      :flagged => post.flagged?,
      :names => post.flag_logs.select { |f| f.success }.map { |f| f.user.username },
      :users => post.flaggers.map { |u| u.as_json.select {|k,v| k == "username" or k.include? "_chat_id" } }
    },
    :feedbacks => post.feedbacks.map { |f| { :feedback_type => f.feedback_type, :user_name => f.user_name || f.user.username} }
  })
end

json.has_more @more
