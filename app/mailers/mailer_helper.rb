module MailerHelper

  def datetime_for_gcal(event)
    event.start_time.utc.strftime("%Y%m%dT%H%M%SZ") + "/" + event.end_time.utc.strftime("%Y%m%dT%H%M%SZ")
  end

  def url_for_gcal(event)
    "http://www.google.com/calendar/event?action=TEMPLATE&text=#{(event.title + ': ' + event.technology.name).gsub(' ','+')}&dates=#{datetime_for_gcal(@event)}&details=#{(event.privacy_humanize).gsub(' ','+')}&location=#{(event.location.addr_one_liner).gsub(' ','+')}&trp=false&sprop=https://make.20liters.org/&sprop=name:20+Liters"
  end
end
