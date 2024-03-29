# frozen_string_literal: true

class BloomerangJob < ApplicationJob
  queue_as :bloomerang_job

  # app options:
  # :buildscheduler
  # :gmailsync
  # :causevoxsync
  def perform(app = nil, method = '', *args)
    return if app.nil?

    BloomerangClient.new(app).__send__(method, *args) if method.present?
  end
end
