# frozen_string_literal: true

class RegistrationReminderJob < ApplicationJob
  queue_as :default

  def perform(*args)
    puts '-+ Cleaning up the RegistrationReminderJob list'
    Delayed::Job.all.each do |job|
      job.destroy if job.name.include?('RegistrationReminderJob')
    end

    puts '-+ Creating registration reminders'
    events = Event.where(reminder_sent_at: nil).where('start_time > ? and start_time < ?', Time.zone.now + 1.days, Time.zone.now + 2.days)

    # maybe an if events.any? / else ??

    events.each do |e|
      # maybe these need to switch to .deliver_now
      # or try EventMailer.delay.remind_admins(e) ??
      EventMailer.remind_admins(e).deliver_later
      puts '-+-+ Admin reminder emails scheduled'
      e.registrations.where(reminder_sent_at: nil).each do |r|
        RegistrationMailer.reminder(r).deliver_later
        # vs. RegistrationMailer.delay.created(r) ??
        r.update(reminder_sent_at: Time.zone.now)
      end
      puts '-+-+ ' + e.count.to_s + ' event reminder email scheduled for admins'
      puts '-+-+ ' + e.registrations.count.to_s + ' registration reminder email(s) scheduled'

      puts '-+-+ No registrations for ' + e.full_title if e.registrations.count < 1

      e.update(reminder_sent_at: Time.zone.now)
    end

    puts '-+-+ No events meet criteria' if events.count < 1

    puts '-+ Done creating'
  end
end
