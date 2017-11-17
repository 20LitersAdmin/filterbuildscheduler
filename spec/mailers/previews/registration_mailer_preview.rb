class RegistrationMailerPreview < ActionMailer::Preview
  def created
    RegistrationMailer.created(Registration.first)
  end

  def reminder
    RegistrationMailer.reminder(Registration.first)
  end
end
