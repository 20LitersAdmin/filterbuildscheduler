# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/setup_mailer
class SetupMailerPreview < ActionMailer::Preview
  def notify
    SetupMailer.notify(Setup.first, User.first)
  end

  def remind
    SetupMailer.remind(Setup.first, User.first)
  end
end
