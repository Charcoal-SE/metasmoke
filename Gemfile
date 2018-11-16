# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include? '/'
  "https://github.com/#{repo_name}.git"
end

gem 'awesome_print'

gem 'aescrypt', '~> 2.0', '>= 2.0.2', github: 'Charcoal-SE/aescrypt'
gem 'audited', '~> 4.4'
gem 'aws-sdk-s3'
gem 'devise', git: 'https://github.com/plataformatec/devise'
gem 'htmlentities', '~> 4.3', '>= 4.3.4'
gem 'httparty'
gem 'jwt'
gem 'loofah', '~> 2.2.1', '>= 2.2.3'
gem 'mysql2'
gem 'octokit', '~> 4.0'
gem 'paperclip', '~> 6.0.0'
gem 'puma'
gem 'rack-cors', '~> 0.4', require: 'rack/cors'
gem 'redcarpet'
gem 'redis', '~> 3.0'
gem 'rolify'
gem 'rotp'
gem 'rqrcode'
gem 'sensible_routes', '~> 0.1.2'
gem 'travis'
gem 'webpacker', '~> 2.0'
gem 'whenever', require: false
gem 'will_paginate', github: 'Undo1/will_paginate'
gem 'will_paginate-bootstrap', github: 'Charcoal-SE/will_paginate-bootstrap'

gem 'flamegraph'
gem 'rack-mini-profiler'
gem 'stackprof'

gem 'chartkick'
gem 'groupdate', '~> 3.0.0'

gem 'rubocop', '~> 0.48.1', require: false, group: :test
gem 'simplecov', require: false, group: :test

gem 'blazer', '2.0.0', github: 'Charcoal-SE/blazer'
gem 'grape', '1.0.0'

# gem 'puma_worker_killer'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.0'
gem 'rack', '>= 2.0.6'
# Use sqlite3 as the database for Active Record
gem 'sqlite3'
# Use SCSS for stylesheets
gem 'sass-rails'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

gem 'capistrano'
gem 'capistrano-bundler'
gem 'capistrano-faster-assets', github: 'Charcoal-SE/capistrano-faster-assets'
gem 'capistrano-locally', require: false
gem 'capistrano-passenger'
gem 'capistrano-rails'
gem 'capistrano-rvm'
gem 'capistrano-secrets-yml'
gem 'capistrano-upload-config'

group :development do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 3.0'

  # Spring speeds up development by keeping your application running
  # in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  # Run `foreman start` to launch a local dev instance;
  # runs both `rails s` and starts the webpack server
  # https://chat.stackexchange.com/transcript/message/38020561#38020561

  gem 'foreman'

  # Export fixtures from local database
  gem 'db_fixtures_dump', github: 'Undo1/db_fixtures_dump'

  # for the RailsPanel Chrome extension
  # https://chrome.google.com/webstore/detail/railspanel/gjpfobpafnhjhbajcjgccbbdofdckggg
  gem 'meta_request'
end

group :test do
  gem 'rails-controller-testing'
  gem 'webmock'
end

gem 'graphiql-rails'
gem 'graphql'
