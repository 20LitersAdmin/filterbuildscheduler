# Preview all emails at http://localhost:3000/rails/mailers/registration_mailer
class RegistrationMailerPreview < ActionMailer::Preview
  def created
    RegistrationMailer.created(Registration.first)
  end

  def reminder
    RegistrationMailer.reminder(Registration.first)
  end
end
