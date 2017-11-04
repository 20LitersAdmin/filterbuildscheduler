class RegistrationReminderJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Event.where('start_time > ? and start_time < ?', Time.now, Time.now.tomorrow).each do |e|
      e.registrations.each do |r|
        RegistrationMailer.reminder r
      end
    end
  end

end
