# frozen_string_literal: true

module MailerHelper
  def name_for_gcal
    '20 Liters'.gsub(' ', '%20')
  end

  def location_for_gcal
    @event.location.addr_one_liner.gsub(' ', '%20')
  end

  def event_title_for_gcal
    "#{@event.title}: #{@event.technology.name}".gsub(' ', '%20')
  end

  def registration_title_for_gcal
    '[20 Liters] Filter Build'.gsub(' ', '%20')
  end

  def details_for_gcal
    @event.privacy_humanize.gsub(' ', '%20')
  end

  def datetime_for_gcal
    @event.start_time.utc.strftime('%Y%m%dT%H%M%SZ') + '/' + @event.end_time.utc.strftime('%Y%m%dT%H%M%SZ')
  end

  def url_for_event_gcal
    "https://www.google.com/calendar/event?action=TEMPLATE&text=#{event_title_for_gcal}&dates=#{datetime_for_gcal}&details=#{details_for_gcal}&location=#{location_for_gcal}&trp=false&sprop=https:/make.20liters.org/&sprop=name:#{name_for_gcal}"
  end

  def url_for_registration_gcal
    "https://www.google.com/calendar/event?action=TEMPLATE&text=#{registration_title_for_gcal}&dates=#{datetime_for_gcal}&details=#{details_for_gcal}&location=#{location_for_gcal}&trp=false&sprop=https:/make.20liters.org/&sprop=name:#{name_for_gcal}"
  end

  def format_changed_time_range(start_time, end_time)
    if start_time.beginning_of_day == end_time.beginning_of_day
      start_time.strftime('%a, %-m/%-d %l:%M%P') + end_time.strftime(' - %l:%M%P')
    else
      start_time.strftime('%a, %-m/%-d %l:%M%P') + end_time.strftime(' to %a, %-m/%-d at %l:%M%P')
    end
  end

  def privacy_case(array)
    case array
    when [false, true]
      'From public to private'
    when [true, false]
      'From private to public'
    else
      ''
    end
  end

  def child_statement_email(technology)
    if technology.family_friendly
      'children as young as 4 can participate'
    else
      'this event is best for ages 12 and up'
    end
  end
end
