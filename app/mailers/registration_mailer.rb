class RegistrationMailer < ApplicationMailer

  default from: "filterbuilds@20liters.org"

  def created(registration)
    @registration = registration
    @recipient = registration.user
    @event = registration.event
    @location = @event.location
    if @recipient.password.blank?
      @token = Devise.token_generator.generate(User, :reset_password_token)
      @recipient.reset_password_token = @token
      @recipient.reset_password_sent_at = Time.now.utc
      @recipient.save
    end

    mail(subject: "[20 Liters] Registration for #{@event.title} @ #{@event.start_time.to_formatted_s(:short)}")
  end

  def reminder(registration)
    @registration = registration
    @recipient = registration.user
    @event = registration.event
    mail(subject: "[20 Liters] Reminder for #{@event.title} @ #{@event.start_time.to_formatted_s(:short)}")
  end

end
