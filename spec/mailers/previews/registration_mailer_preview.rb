# Preview all emails at http://localhost:3000/rails/mailers/registration_mailer
class RegistrationMailerPreview < ActionMailer::Preview
  def created
    RegistrationMailer.created(Registration.first)
  end

  def reminder
    RegistrationMailer.reminder(Registration.first)
  end

  def event_changed
    event = Event.first
    event.start_time = DateTime.new(2017, 11, 8, 16, 0, 0, '-05:00')
    event.end_time = DateTime.new(2017, 11, 8, 21, 0, 0, '-05:00')
    event.technology_id = 2
    event.location_id = 2
    event.is_private = true

    RegistrationMailer.event_changed(Registration.first, event)
  end

  def event_cancelled
    RegistrationMailer.event_cancelled(Registration.first)
  end

  def event_results
    RegistrationMailer.event_results(Registration.first)
  end
end
