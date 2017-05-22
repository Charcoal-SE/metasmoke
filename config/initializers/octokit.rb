# frozen_string_literal: true

Octokit.configure do |c|
  c.login = AppConfig['github']['username']
  c.password = AppConfig['github']['password']
end
