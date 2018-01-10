class EventMailer < ApplicationMailer
  helper MailerHelper
  default from: "filterbuilds@20liters.org"

  # content_type "multipart/mixed"

  def created(event, user)
    @event = event
    @user = user
    @recipients = User.where(send_notification_emails: true).map { |r| r.email }
    @location = event.location
    @summary = "[20 Liters] " + event.title + ": " + event.technology.name
    @description = event.privacy_humanize
    @attachment_title = "20Liters_filterbuild_" + @event.start_time.strftime("%Y%m%dT%H%M") + ".ical"

    if @event.leaders_registered.count == 1
      @leader_count_text = "The leader is:"
    elsif @event.leaders_registered.count > 1
      @leader_count_text = "The leaders are:"
    end

    cal = Icalendar::Calendar.new
    cal.event do |e|
      e.dtstart = @event.start_time
      e.dtend = @event.end_time
      e.organizer = "mailto:filterbuilds@20liters.org"
      e.attendee = @recipients
      e.location = @location.addr_one_liner
      e.summary = @summary
      e.description = @description
    end
    cal.append_custom_property('METHOD', 'REQUEST')
    mail.attachments[@attachment_title] = { mime_type: 'text/calendar', content: cal.to_ical }
    mail(to: @recipients, subject: '[20 Liters] New Filter Build Scheduled')
  end

  def reminder(event)
    @event = event
    @recipients = User.where(send_notification_emails: true).map { |r| r.email }
    @location = event.location
    if @event.leaders_registered.count == 1
      @leader_count_text = "The leader is:"
    elsif @event.leaders_registered.count > 1
      @leader_count_text = "The leaders are:"
    end

    mail(to: @recipients, subject: '[20 Liters] Upcoming Filter Build Reminder')
  end

  def changed(event, user)
    @event = event
    @user = user
    @recipients = User.where(send_notification_emails: true).map { |r| r.email }
    @summary = "[20 Liters] " + event.title + ": " + event.technology.name
    @description = event.privacy_humanize
    @attachment_title = "20Liters_filterbuild_" + @event.start_time.strftime("%Y%m%dT%H%M") + ".ical"

    event.changes.each_pair { |k, v| instance_variable_set("@#{k}", v) }
    @location = event.location
    @location_was = Location.find(event.location_id_was)
    @technology = event.technology
    @technology_was = Technology.find(event.technology_id_was)

    if @start_time || @end_time || @location_id || @technology_id
      @registered_users_notified = true
    end

    cal = Icalendar::Calendar.new
    cal.event do |e|
      e.dtstart = @event.start_time
      e.dtend = @event.end_time
      e.organizer = "mailto:filterbuilds@20liters.org"
      e.attendee = @recipients
      e.location = @location.addr_one_liner
      e.summary = @summary
      e.description = @description
    end
    cal.append_custom_property('METHOD', 'REQUEST')
    mail.attachments[@attachment_title] = { mime_type: 'text/calendar', content: cal.to_ical }
    mail(to: @recipients, subject: '[20 Liters] NOTICE: Build Event Changed')
  end

  def cancelled(event, user)
    @event = event
    @user = user
    @recipients = User.where(send_notification_emails: true).map { |r| r.email }
    @location = @event.location
    @registrations = @event.registrations

    if @event.leaders_registered.count == 1
      @leader_count_text = "The leader was:"
    elsif @event.leaders_registered.count > 1
      @leader_count_text = "The leaders were:"
    end

    mail(to: @recipients, subject: '[20 Liters] NOTICE: Build Event Cancelled')
  end

  def messenger(registration, subject, message, sender)
    @registration = registration
    @event = @registration.event
    @subject = '[20 Liters] ' + subject
    @message = message
    @sender = sender

    mail(to: @registration.user.email, subject: @subject)
  end

  def messenger_reporter(event, subject, message, sender)
    @event = event
    @subject = '[20 Liters] ' + subject
    @message = message
    @sender = sender
    @admins = User.where(is_admin: true).map { |u| u.email }

    mail(to: @admins, subject: "[20 Liters] A Leader sent a message")
  end
end
