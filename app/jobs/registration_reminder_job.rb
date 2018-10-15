# frozen_string_literal: true

class RegistrationReminderJob < ApplicationJob
  queue_as :default

  def perform(*args)
    puts "-+ Creating registration reminders"
    # events = Event.where(reminder_sent_at: nil).where('start_time > ? and start_time < ?', Time.zone.now + 1.days, Time.zone.now + 2.days)
    events = Event.where(id: [49,50]).where(reminder_sent_at: nil)
    
    events.each do |e|
      EventMailer.remind_admins(e).deliver_later
      puts "-+-+ Admin reminder emails scheduled"
      e.registrations.where(reminder_sent_at: nil).each do |r|
        RegistrationMailer.reminder(r).deliver_later
        r.update(reminder_sent_at: Time.zone.now)
      end
      puts "-+-+ " + e.registrations.count.to_s + " registration reminder email(s) scheduled"

      if e.registrations.count < 1
        puts "-+-+ No registrations for " + e.full_title
      end

      e.update(reminder_sent_at: Time.zone.now)
    end

    if events.count < 1
      puts "-+-+ No events meet criteria"
    end

    puts "-+ Done creating"
  end
end
