# frozen_string_literal: true

class RegistrationReminderJob < ApplicationJob
  queue_as :registration_reminder

  def perform(*_args)
    events = Event.pre_reminders.future.within_days(2)

    events.each do |e|
      EventMailer.remind_admins(e).deliver_now
      e.registrations.pre_reminders.each do |r|
        RegistrationMailer.reminder(r).deliver_now
        r.update(reminder_sent_at: Time.zone.now)
      end

      e.update(reminder_sent_at: Time.zone.now)
    end
  end
end
