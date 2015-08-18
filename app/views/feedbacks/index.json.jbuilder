json.array!(@feedbacks) do |feedback|
  json.extract! feedback, :id
  json.url feedback_url(feedback, format: :json)
end
