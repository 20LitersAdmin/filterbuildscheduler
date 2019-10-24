# frozen_string_literal: true

require_relative 'boot'
require 'dotenv/load'
require 'csv'
require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BuildPlanner
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    config.time_zone = 'Eastern Time (US & Canada)'

    config.active_job.queue_adapter = :delayed_job

    config.action_mailer.default_url_options = { host: 'make.20liters.org' }
    config.action_mailer.preview_path = "#{Rails.root}/spec/mailers/previews"

    config.logger = ActiveSupport::Logger.new("log/#{Rails.env}.log")

    config.serve_static_assets = true

    config.generators do |g|
      g.test_framework :rspec
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
