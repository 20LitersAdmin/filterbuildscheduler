class RegistrationReminderJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Event.where('start_time > ? and start_time < ?', Time.zone.now.tomorrow, Time.zone.now + 2.days).each do |e|
      EventMailer.reminder e
      e.registrations.each do |r|
        RegistrationMailer.reminder r
      end
    end
  end

end
