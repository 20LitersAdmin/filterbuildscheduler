class RegistrationMailer < ApplicationMailer

  default from: "filterbuilds@20liters.org"

  def created(registration)
    @registration = registration
    @recipient = registration.user
    @event = registration.event
    mail(subject: "[20 Liters] Registration for #{@event.name} @ #{@event.start_time.to_formatted_s(:short)}")
  end

  def reminder(registration)
    @registration = registration
    @recipient = registration.user
    @event = registration.event
    mail(subject: "[20 Liters] Reminder for #{@event.name} @ #{@event.start_time.to_formatted_s(:short)}")
  end

end
