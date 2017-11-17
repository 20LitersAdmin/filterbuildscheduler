class DeviseMailer < Devise::Mailer
  helper MailerHelper
  include Devise::Controllers::UrlHelpers
  default template_path: 'devise/mailer'
  layout 'mailer'
  default from: "filterbuilds@20liters.org"

  def confirmation_instructions
    mail(to: @email, subject: "[20 Liters] Confirm your account" )
  end

  def email_changed
  end

  def password_change
  end

  def reset_password_instructions
  end

  def unlock_instructions
  end
end
