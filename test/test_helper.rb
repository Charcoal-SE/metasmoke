# frozen_string_literal: true

require 'simplecov'
require 'webmock/minitest'
SimpleCov.start 'rails'

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
require 'rails/test_help'

module ActiveSupport
  class TestCase
    include ActiveJob::TestHelper
    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

module ActionController
  class TestCase
    include Devise::Test::ControllerHelpers
  end
end
