module EventsHelper
  def time_for_form(event_time)
    if event_time.present?
      event_time.to_time.iso8601
    else
      Time.now.iso8601
    end
  end
end
