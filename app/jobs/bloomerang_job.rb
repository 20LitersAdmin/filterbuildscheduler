# frozen_string_literal: true

class BloomerangJob < ApplicationJob
  queue_as :bloomerang_job

  # app options:
  # :buildscheduler
  # :gmailsync
  # :causevoxsync
  def perform(app = nil, method = '', *args)
    return if app.nil? || method.blank?

    Rollbar.info("BloomerangJob:", app:, method:, args:)
    BloomerangClient.new(app).__send__(method, *args)
  end
end
