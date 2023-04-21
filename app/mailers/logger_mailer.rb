# frozen_string_literal: true

class LoggerMailer < ApplicationMailer
  default from: '20 Liters <filterbuilds@20liters.org>', reply_to: 'filterbuilds@20liters.org'
  # TEMP hacky logger-ish email service
  # user is expected to be OauthUser, but just needs to have #name and #email attrs
  def notify(user, subject, message)
    @message = message
    @user = user
    mail(to: @user.email, subject:)
  end
end
