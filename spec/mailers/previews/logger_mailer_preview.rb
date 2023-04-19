# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/devise_mailer
class LoggerMailerPreview < ActionMailer::Preview
  def notify
    LoggerMailer.notify(OauthUser.first, "Logger-style notify", "this is a message that tells us something happened.")
  end
end
