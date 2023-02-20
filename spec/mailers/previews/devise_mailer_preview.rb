# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/devise_mailer
class DeviseMailerPreview < ActionMailer::Preview
  def password_change
    DeviseMailer.password_change(User.first, {})
  end

  def reset_password_instructions
    DeviseMailer.reset_password_instructions(User.first, 'faketoken', {})
  end
end
