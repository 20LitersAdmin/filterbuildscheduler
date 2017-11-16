class RegistrationMailerPreview < ActionMailer::Preview
  def created
    RegistrationMailer.created(Registration.last)
  end

  def reminder
    RegistrationMailer.reminder(Registration.last)
  end
end
