require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Metasmoke
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run 'rake -D time' for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Prevent SE write codes (used to get a token) from showing up in the logs
    config.filter_parameters += [:code]

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        # 'http://stackoverflow.com', 'http://superuser.com', 'http://serverfault.com',
        # /^http:\/\/.*.stackexchange.com$/, 'https://stackoverflow.com', 'https://superuser.com',
        # 'https://serverfault.com', /^https:\/\/.*.stackexchange.com$/

        resource '/posts/recent.json', headers: :any, methods: [:get]
        resource '/posts/add_feedback', headers: :any, methods: [:post], credentials: true

        resource '/api/*', headers: :any, methods: [:get, :post]
        resource '/api/w/*', headers: :any, methods: [:post], credentials: true

        resource '/oauth/token', headers: :any, methods: [:get]
      end
    end

    config.after_initialize do
      # Only authorize MiniProfiler if none of the blacklisted pp modes are specified.
      Rack::MiniProfiler.config.authorization_mode = :allow_all
      Rack::MiniProfiler.config.pre_authorize_cb = lambda { |env|
        blacklisted_modes = [/pp=env/, /pp=profile-gc/, /pp=profile-memory/, /pp=analyze-memory/]

        blacklisted_modes.none? do |item|
          item =~ env['QUERY_STRING']
        end
      }
    end
  end
end
