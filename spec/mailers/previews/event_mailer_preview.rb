# Preview all emails at http://localhost:3000/rails/mailers/event_mailer
class EventMailerPreview < ActionMailer::Preview
  def created
    EventMailer.created(Event.first, User.first)
  end

  def reminder
    EventMailer.reminder(Event.last)
  end

  def changed
    event = Event.first
    event.start_time = DateTime.new(2017, 11, 8, 16, 0, 0, '-05:00')
    event.end_time = DateTime.new(2017, 11, 8, 21, 0, 0, '-05:00')
    event.technology_id = 2
    event.is_private = true

    EventMailer.changed(event, User.first)
  end

  def cancelled
    EventMailer.cancelled(Event.first, User.first)
  end
end
