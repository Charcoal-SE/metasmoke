json.array!(@posts) do |post|
  json.extract! post, :id, :reason_id, :title, :body, :link, :catch_date, :result, :message_link, :message_user
  json.url post_url(post, format: :json)
end
