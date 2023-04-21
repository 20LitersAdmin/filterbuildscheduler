# frozen_string_literal: true

require 'sidekiq-scheduler'

class RegistrationReminderJob < ApplicationJob
  queue_as :registration_reminder

  def perform(*_args)
    puts 'Scheduling Registration Reminders...'

    events = Event.pre_reminders.future.within_days(2)

    return 'Done. No events within 2 days.' if events.none?

    e_count = events.size
    r_count = 0

    events.each do |e|
      EventMailer.remind_admins(e).deliver_now
      registrations = e.registrations.pre_reminders

      r_count += registrations.size

      registrations.each do |r|
        RegistrationMailer.reminder(r).deliver_now
        r.update(reminder_sent_at: Time.zone.now)
      end

      e.update(reminder_sent_at: Time.zone.now)
    end

    puts "Done. Sent #{r_count} reminders for #{e_count} events."

    # TEMP logging HACK
    LoggerMailer.notify(OauthUser.first, 'Registration Reminder Job', 'Registration Reminder Job just ran.').deliver_now
  end
end
