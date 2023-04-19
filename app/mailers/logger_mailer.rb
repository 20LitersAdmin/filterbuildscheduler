# frozen_string_literal: true

class LoggerMailer < ActionMailer::Base
  # TEMP hacky logger-ish email service
  # user is expected to be OauthUser, but just needs to have #name and #email attrs
  def notify(user, subject, message)
    @message = message
    @user = user
    mail(to: @user.email, subject:)
  end
end
