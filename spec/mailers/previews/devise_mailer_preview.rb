# Preview all emails at http://localhost:3000/rails/mailers/devise_mailer
class DeviseMailerPreview < ActionMailer::Preview
  def confirmation_instructions
    DeviseMailer.confirmation_instructions
  end

  def email_changed
    DeviseMailer.email_changed
  end

  def password_change
    DeviseMailer.password_change
  end

  def reset_password_instructions
    DeviseMailer.reset_password_instructions
  end

  def unlock_instructions
    DeviseMailer.unlock_instructions
  end
end
