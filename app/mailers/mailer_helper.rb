module MailerHelper

  def datetime_for_gcal
    @event.start_time.utc.strftime("%Y%m%dT%H%M%SZ") + "/" + @event.end_time.utc.strftime("%Y%m%dT%H%M%SZ")
  end

  def url_for_event_gcal
    "http://www.google.com/calendar/event?action=TEMPLATE&text=#{(@event.title + ': ' + @event.technology.name).gsub(' ','%20')}&dates=#{datetime_for_gcal}&details=#{(@event.privacy_humanize).gsub(' ','%20')}&location=#{(@event.location.addr_one_liner).gsub(' ','%20')}&trp=false&sprop=https://make.20liters.org/&sprop=name:20%20Liters"
  end

  def url_for_registration_gcal
    "http://www.google.com/calendar/event?action=TEMPLATE&text=[20%20Liters]%20Filter%20Build&dates=#{datetime_for_gcal}&details=#{@details}&location=#{(@event.location.addr_one_liner).gsub(' ','%20')}&trp=false&sprop=https://make.20liters.org/&sprop=name:20%20Liters"
  end
end
