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

    # TEMP logging HACK
    LoggerMailer.notify(OauthUser.first, "Bloomerang Client #{method} performed by job", "Bloomerang Job just triggered Bloomerang Client's #{method} method.").deliver_now
  end
end
