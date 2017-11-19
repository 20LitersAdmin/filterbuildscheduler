# Preview all emails at http://localhost:3000/rails/mailers/event_mailer
class EventMailerPreview < ActionMailer::Preview
  def created
    EventMailer.created(Event.first, User.first)
  end

  def reminder
    EventMailer.reminder(Event.last)
  end
end
