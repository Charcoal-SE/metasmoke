# frozen_string_literal: true

Octokit.configure do |c|
  if AppConfig['github']['access_token'].present?
    c.access_token = AppConfig['github']['access_token']
  else
    c.login = AppConfig['github']['username']
    c.password = AppConfig['github']['password']
  end
end
