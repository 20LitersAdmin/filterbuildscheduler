class GoogleCalendar < ApplicationRecord
  # https://github.com/northworld/google_calendar
  require 'google_calendar'

  def initialize
    @cal = Google::Calendar.new(
      client_id: ENV['GCAL_CLIENT_ID'],
      client_secret: ENV['GCAL_SECRET'],
      calendar: ENV['GCAL_CAL_ID'],
      redirect_url: "urn:ietf:wg:oauth:2.0:oob",
      refresh_token: ENV['GCAL_REFRESH_TOKEN']
    )
  end

  def create(event)
    gcal_event = @cal.create_event do |e|
      e.title = event.technology.name + " Build"
      e.location = event.location.addr_one_liner
      e.description = event.privacy_humanize
      e.start_time = event.start_time
      e.end_time = event.end_time
    end

    # return the gcal_event.id and save it to event.gcal_id
    event.gcal_id = gcal_event.id
    event.save
  end

  def update(event)
    @cal.find_event_by_id(event.gcal_id) do |e|
      e.title = event.technology.name + " Build"
      e.location = event.location.addr_one_liner
      e.description = event.privacy_humanize
      e.start_time = event.start_time
      e.end_time = event.end_time
    end
  end

  def destroy(event)
    gcal_event = @cal.find_event_by_id(event.gcal_id)
    gcal_event.delete
  end
end
