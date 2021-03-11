# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/registration_mailer
class RegistrationMailerPreview < ActionMailer::Preview
  def created
    RegistrationMailer.created(Registration.last)
  end

  def reminder
    RegistrationMailer.reminder(Registration.last)
  end

  def event_changed
    event = Event.last
    event.start_time = Time.new(2017, 11, 8, 16, 0, 0, '-05:00')
    event.end_time = Time.new(2017, 11, 8, 21, 0, 0, '-05:00')
    event.technology_id = 2
    event.location_id = 2
    event.is_private = true

    RegistrationMailer.event_changed(Registration.last, event)
  end

  def event_cancelled
    RegistrationMailer.event_cancelled(Registration.last.id)
  end

  def event_results
    RegistrationMailer.event_results(Registration.last)
  end
end
