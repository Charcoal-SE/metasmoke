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
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    config.middleware.insert_before 0, "Rack::Cors" do
      allow do
        origins '*' #'http://stackoverflow.com', 'http://superuser.com', 'http://serverfault.com', /^http:\/\/.*.stackexchange.com$/, 'https://stackoverflow.com', 'https://superuser.com', 'https://serverfault.com', /^https:\/\/.*.stackexchange.com$/

        resource '/posts/recent.json', :headers => :any, :methods => [:get]
        resource '/posts/add_feedback', :headers => :any, :methods => [:post], :credentials => true
      end
    end
  end
end
