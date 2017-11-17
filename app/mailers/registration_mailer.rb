class RegistrationMailer < ApplicationMailer
  helper MailerHelper

  default from: "filterbuilds@20liters.org"

  def created(registration)
    @registration = registration
    @recipient = registration.user
    @event = registration.event
    @location = @event.location

    if @recipient.password.blank?
      @token = Devise.token_generator.generate(User, :reset_password_token)
      @recipient.reset_password_token = @token[1]
      @token = @token[0]
      @recipient.reset_password_sent_at = Time.now.utc
      @recipient.save
    end

    if @event.leaders_registered.count == 1
      @leader_count_text = "Your leader is:"
    elsif @event.leaders_registered.count > 1
      @leader_count_text = "Your leaders are:"
    end

    mail(to: @recipient.email, subject: "[20 Liters] You registered for a filter build on #{@event.mailer_time}")
  end

  def reminder(registration)
    @registration = registration
    @recipient = registration.user
    @event = registration.event
    @location = @event.location

    if @event.leaders_registered.count == 1
      @leader_count_text = "Your leader is:"
    elsif @event.leaders_registered.count > 1
      @leader_count_text = "Your leaders are:"
    end

    mail(to: @recipient.email, subject: "[20 Liters] Reminder: Filter build on #{@event.mailer_time}")
  end

end
