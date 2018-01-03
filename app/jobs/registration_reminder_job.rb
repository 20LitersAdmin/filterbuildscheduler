class RegistrationReminderJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Event.where('start_time > ? and start_time < ?', Time.zone.now + 1.days, Time.zone.now + 2.days).each do |e|
      EventMailer.delay.reminder(e)
      e.registrations.each do |r|
        RegistrationMailer.delay.reminder(r)
      end
    end
  end

end
