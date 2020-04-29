# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/event_mailer
class EventMailerPreview < ActionMailer::Preview
  def created
    EventMailer.created(Event.first, User.first)
  end

  def remind_admins
    EventMailer.remind_admins(Event.last)
  end

  def changed
    event = Event.first
    event.start_time = DateTime.new(2017, 11, 8, 16, 0, 0, '-05:00')
    event.end_time = DateTime.new(2017, 11, 8, 21, 0, 0, '-05:00')
    event.technology_id = 2
    event.location_id = 2
    event.is_private = true

    EventMailer.changed(event, User.first)
  end

  def cancelled
    EventMailer.cancelled(Event.first.id, User.first)
  end

  def messenger
    EventMailer.messenger(Event.first.registrations.second, "The Subject", "The Message goes a little something like this", User.first)
  end

  def messenger_reporter
    EventMailer.messenger_reporter(Event.first, "The Subject", "The Message goes a litle something like this", User.first)
  end

  def replicated
    events = Event.limit(5)
    initiator = User.first
    EventMailer.replicated(events, initiator)
  end
end
