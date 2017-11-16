module EventsHelper
  def time_for_form(event_time)
    if event_time.present?
      event_time.to_time.iso8601
    else
      Time.now.strftime("%l:%M %P")
    end

  end

  def date_for_form(event_date)
    if event_date.present?
      event_time.start_time.to_date
    else
      Date.today.strftime("%m/%d/%Y")
    end
  end
end
