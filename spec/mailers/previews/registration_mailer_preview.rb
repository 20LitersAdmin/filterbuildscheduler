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
    event.location_id = 2

    RegistrationMailer.event_changed(Registration.last, event)
  end

  def event_cancelled
    reg = Registration.last
    reg.update_columns(guests_registered: 2)
    RegistrationMailer.event_cancelled(reg.id)
  end

  def event_results
    reg = Event.with_results.last.registrations.last
    reg.update_columns(guests_attended: 2)
    RegistrationMailer.event_results(reg)
  end
end
