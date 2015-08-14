json.array!(@regexes) do |regex|
  json.extract! regex, :id, :reason
  json.url regex_url(regex, format: :json)
end
