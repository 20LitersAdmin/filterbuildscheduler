# frozen_string_literal: true

require_relative 'boot'
require 'csv'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_storage/engine'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
# require 'action_mailbox/engine'
# require 'action_text/engine'
require 'action_view/railtie'
require 'action_cable/engine'
require 'sprockets/railtie'
# require 'rails/test_unit/railtie'
require 'sidekiq/api'

require 'google/apis/gmail_v1'
# require 'google/api_client/client_secrets'

require 'bloomerang'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BuildPlanner
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    config.time_zone = 'Eastern Time (US & Canada)'

    config.active_job.queue_adapter = :sidekiq

    config.action_mailer.default_url_options = { host: 'make.20liters.org' }
    config.action_mailer.preview_path = "#{Rails.root}/spec/mailers/previews"

    config.logger = ActiveSupport::Logger.new("log/#{Rails.env}.log")

    config.serve_static_assets = true

    config.generators do |g|
      g.test_framework :rspec
    end
  end
end

Rails.application.config.assets.configure do |env|
  env.export_concurrent = false
end
