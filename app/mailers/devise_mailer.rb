# frozen_string_literal: true

class DeviseMailer < Devise::Mailer
  helper MailerHelper
  include Devise::Controllers::UrlHelpers
  default template_path: 'users/mailer'
  layout 'mailer'
  default from: '20 Liters <filterbuilds@20liters.org>', reply_to: 'filterbuilds@20liters.org'

  def password_change(user, _opts = {})
    @user = user
    mail(to: @user.email, subject: '[20 Liters] Your password was changed')
  end

  def reset_password_instructions(user, token, _opts = {})
    @user = user
    @token = token
    mail(to: @user.email, subject: '[20 Liters] Reset your password')
  end
end
