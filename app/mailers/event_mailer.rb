class EventMailer < ApplicationMailer
  helper MailerHelper
  default from: "filterbuilds@20liters.org"

  # content_type "multipart/mixed"

  def send_ical(event)
    @event = event
    @recipients = User.where(send_notification_emails: true).map { |r| r.email }
    @location = event.location.addr_one_liner
    @summary = event.title + ": " + event.technology.name
    @description = event.privacy_humanize

    cal = Icalendar::Calendar.new
    cal.event do |e|
      e.dtstart = @event.start_time
      e.dtend = @event.end_time
      e.organizer = "mailto:filterbuilds@20liters.org"
      e.attendee = @recipients
      e.location = @location
      e.summary = @summary
      e.description = @description
    end
    cal.append_custom_property('METHOD', 'REQUEST')
    mail.attachments['20Liters_filterbuild_#{@event.start_time.trftime("%Y%m%dT%H%M%S")}.ics'] = { mime_type: 'text/calendar', content: cal.to_ical }
    mail(to: @recipients, subject: '20 Liters: New Filter Build Event Scheduled')
  end


end
