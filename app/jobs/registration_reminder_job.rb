# frozen_string_literal: true

class RegistrationReminderJob < ApplicationJob
  queue_as :default

  def perform(*args)
    puts "-+ Creating registration reminders"
    events = Event.where('start_time > ? and start_time < ?', Time.zone.now + 1.days, Time.zone.now + 2.days)
    
    events.each do |e|
      EventMailer.remind_admins(e).deliver_later
      puts "-+-+ Admin reminder emails scheduled"
      e.registrations.each do |r|
        RegistrationMailer.reminder(r).deliver!
      end
      puts "-+-+ " + e.registrations.count.to_s + " registration reminder email(s) scheduled"

      if e.registrations.count < 1
        puts "-+-+ No registrations for " + e.full_title
      end
    end

    if events.count < 1
      puts "-+-+ No events within 24 to 48 hours"
    end

    puts "-+ Done creating"
  end
end
