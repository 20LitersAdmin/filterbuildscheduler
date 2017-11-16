# Preview all emails at http://localhost:3000/rails/mailers/event_mailer
class EventMailerPreview < ActionMailer::Preview
  def send_ical
    EventMailer.send_ical(Event.first)
  end
end
