class RegistrationMailer < ApplicationMailer
  helper MailerHelper

  default from: "filterbuilds@20liters.org"

  def created(registration)
    @registration = registration
    @recipient = registration.user
    @event = registration.event
    @location = @event.location
    @summary = "[20 Liters] Filter Build: " + @event.technology.name
    @attachment_title = "20Liters_filterbuild_" + @event.start_time.strftime("%Y%m%dT%H%M") + ".ical"

    if @event.leaders_registered.count == 1
      @leader_count_text = "Your leader is:"
    elsif @event.leaders_registered.count > 1
      @leader_count_text = "Your leaders are:"
    end

    if @recipient.encrypted_password.blank?
      @token = Devise.token_generator.generate(User, :reset_password_token)
      @recipient.reset_password_token = @token[1]
      @token = @token[0]
      @recipient.reset_password_sent_at = Time.now.utc
      @recipient.save
    end

    @description = render partial: 'details.text'
    @details = @description.gsub("\n","%0A").gsub(" ","%20")

    cal = Icalendar::Calendar.new
    cal.event do |e|
      e.dtstart = @event.start_time
      e.dtend = @event.end_time
      e.organizer = "mailto:filterbuilds@20liters.org"
      e.attendee = @recipient
      e.location = @location.addr_one_liner
      e.summary = @summary
      e.description = @description
    end
    cal.append_custom_property('METHOD', 'REQUEST')
    mail.attachments[@attachment_title] = { mime_type: 'text/calendar', content: cal.to_ical }

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
