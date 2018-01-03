class RegistrationReminderJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Event.where('start_time > ? and start_time < ?', Time.zone.now + 1.days, Time.zone.now + 2.days).each do |e|
      EventMailer.remind_admins(e).deliver_later
      e.registrations.each do |r|
        RegistrationMailer.reminder(r).deliver_later
      end
    end
  end

end
