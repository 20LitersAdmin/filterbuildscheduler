# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'spec_helper'
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!
# note: require 'devise' after require 'rspec/rails'
require 'devise'
require 'support/cleanup_crew'

# These are only for system specs and should probably be moved
require 'capybara/rspec'
require 'selenium-webdriver'
require 'support/form_helper'
require 'rspec/retry'

ActiveRecord::Migration.maintain_test_schema!
Capybara.server = :puma
Capybara.javascript_driver = :selenium
FactoryBot.use_parent_strategy = false
ActiveJob::Base.queue_adapter = :test

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.include Devise::Test::IntegrationHelpers, type: :system
  config.include CleanupCrew, type: :system
  config.include FormHelper, type: :system

  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # Rspec/retry settings
  # show retry status in spec process
  config.verbose_retry = true
  # show exception that triggers a retry if verbose_retry is set to true
  config.display_try_failure_messages = true
  # Only retry when Selenium raises Net::ReadTimeout
  # config.exceptions_to_retry = [Net::ReadTimeout]

  config.expect_with :rspec do |expectations|
    expectations.syntax = %i[should expect]
  end

  config.before(:each) do
    Faker::UniqueGenerator.clear
  end

  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :selenium_chrome_headless
    Capybara.page.driver.browser.manage.window.resize_to(1920, 2024)
  end

  config.after :suite do
    CleanupCrew.clean_up!
  end

  config.around :each, :js do |ex|
    ex.run_with_retry retry: 2
  end
end

Capybara.default_host = 'http://localhost:3000/'

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    # Choose a test framework:
    with.test_framework :rspec
    # Choose one or more libraries:
    with.library :rails
  end
end
