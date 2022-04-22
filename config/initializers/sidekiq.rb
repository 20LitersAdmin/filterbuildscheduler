# frozen_string_literal: true

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1'), size: 4, network_timeout: 5 }
end

Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1'), size: 4, network_timeout: 5 }
end

# Delayed extensions provide a very easy and simple way to
# make method calls asynchronous.
# By default, all class methods and ActionMailer deliveries
# can be performed asynchronously.
Sidekiq::Extensions.enable_delay!
