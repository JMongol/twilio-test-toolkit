# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"

Rails.backtrace_cleaner.remove_silencers!

require 'rspec/rails'

# Set up capybara integration
require 'capybara/rspec'
require 'capybara/rails'

# Our gem
require 'twilio-test-toolkit'

RSpec.configure do |config|
  config.include TwilioTestToolkit::DSL, :type => :request
end