# frozen_string_literal: true

class RegistrationMailer < ApplicationMailer
  helper MailerHelper

  def created(registration)
    @registration = registration
    @recipient = @registration.user
    @event = @registration.event
    @location = @event.location
    @technology = @event.technology

    if @event.leaders_registered.count == 1
      @leader_count_text = 'Your leader is:'
    elsif @event.leaders_registered.count > 1
      @leader_count_text = 'Your leaders are:'
    end

    @summary = "[20 Liters] Filter Build: #{@event.technology.name}"
    @description = render partial: 'details'
    @details = @description.gsub("\n", '%0A').gsub(' ', '%20')
    @attachment_title = "20Liters_filterbuild_#{@event.start_time.strftime('%Y%m%dT%H%M')}.ical"

    cal = Icalendar::Calendar.new
    cal.event do |e|
      e.dtstart = @event.start_time
      e.dtend = @event.end_time
      e.organizer = 'mailto:filterbuilds@20liters.org'
      e.attendee = @recipient
      e.location = @location.addr_one_liner
      e.summary = @summary
      e.description = @description
    end
    cal.append_custom_property('METHOD', 'REQUEST')
    # mail.attachments[@attachment_title] = { mime_type: 'text/calendar', content: cal.to_ical }

    mail(to: @recipient.email, subject: "[20 Liters] You registered for a filter build on #{@event.mailer_time}")
  end

  def event_changed(registration, event)
    @registration = registration
    @recipient = registration.user
    @event = event
    @summary = "[20 Liters] Filter Build: #{@event.technology.name}"
    @attachment_title = "20Liters_filterbuild_#{@event.start_time.strftime('%Y%m%dT%H%M')}.ical"

    if @event.leaders_registered.count == 1
      @leader_count_text = 'Your leader is:'
    elsif @event.leaders_registered.count > 1
      @leader_count_text = 'Your leaders are:'
    end

    @event.changes.each_pair { |k, v| instance_variable_set("@#{k}", v) }
    @location = @event.location
    @location_was = Location.find(@event.location_id_was)
    @technology = @event.technology
    @technology_was = Technology.find(@event.technology_id_was)

    @description = render partial: 'details.text'
    @details = @description.gsub("\n", '%0A').gsub(' ', '%20')

    cal = Icalendar::Calendar.new
    cal.event do |e|
      e.dtstart = @event.start_time
      e.dtend = @event.end_time
      e.organizer = 'mailto:filterbuilds@20liters.org'
      e.attendee = @recipient
      e.location = @location.addr_one_liner
      e.summary = @summary
      e.description = @description
    end
    cal.append_custom_property('METHOD', 'REQUEST')
    # mail.attachments[@attachment_title] = { mime_type: 'text/calendar', content: cal.to_ical }

    mail(to: @recipient.email, subject: '[20 Liters] NOTICE: Build Event Changed')
  end

  def reminder(registration)
    @registration = registration
    @recipient = registration.user

    return if @recipient.email_opt_out

    @event = registration.event
    @location = @event.location
    @technology = @event.technology

    if @event.leaders_registered.count == 1
      @leader_count_text = 'Your leader is:'
    elsif @event.leaders_registered.count > 1
      @leader_count_text = 'Your leaders are:'
    end

    mail(to: @recipient.email, subject: "[20 Liters] Reminder: Filter build on #{@event.mailer_time}")
  end

  def event_cancelled(registration)
    @registration = registration
    @recipient = @registration.user
    @event = @registration.event
    @location = @event.location

    mail(to: @recipient.email, subject: '[20 Liters] NOTICE: Build Event Cancelled')
  end

  def event_results(registration)
    @registration = registration
    @recipient = registration.user

    return if @recipient.email_opt_out

    @event = registration.event
    @location = @event.location
    @technology = @event.technology

    mail(to: @recipient.email, subject: '[20 Liters] Results from the filter build!')
  end
end
