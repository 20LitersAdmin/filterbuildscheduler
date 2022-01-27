# frozen_string_literal: true

class SetupMailer < ApplicationMailer
  helper MailerHelper
  default from: 'filterbuilds@20liters.org'

  def notify(setup, user)
    @setup = setup
    @user = user
    @event = @setup.event
    @location = @event.location
    @summary = "[20 Liters] #{@setup.summary}"
    @attachment_title = "20Liters_filterbuild_setup_#{@setup.date.strftime('%Y%m%dT%H%M')}.ical"

    cal = Icalendar::Calendar.new
    cal.event do |e|
      e.dtstart = @setup.date
      e.dtend = @setup.end_time
      e.organizer = 'mailto:filterbuilds@20liters.org'
      e.attendee = @user
      e.location = @location.addr_one_liner
      e.summary = @summary
      e.description = "As of #{Date.today} there are #{@setup.event.builders_registered.size} builders registered for this event."
    end
    cal.append_custom_property('METHOD', 'REQUEST')
    mail.attachments[@attachment_title] = { mime_type: 'text/calendar', content: cal.to_ical }
    mail(to: @user.email, subject: @summary)
  end

  def remind(setup, user)
    @setup = setup
    @user = user
    @event = @setup.event
    @location = @event.location
    @summary = "[20 Liters] #{@setup.summary}}"
    mail(to: @user.email, subject: @summary)
  end
end
