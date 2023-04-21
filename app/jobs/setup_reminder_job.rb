# frozen_string_literal: true

require 'sidekiq-scheduler'

class SetupReminderJob < ApplicationJob
  queue_as :setup_reminder

  def perform(*_args)
    puts 'Scheduling Setup Reminders...'

    setups = Setup.pre_reminders.days_from_now(2)

    return 'Done. No setups within the next 2 days' if setups.none?

    s_count = setups.size
    r_count = 0

    setups.each do |setup|
      next if setup.users.empty?

      setup.users.each do |user|
        next if setup.reminder_sent_to.include? user.id

        r_count += 1

        SetupMailer.remind(setup, user).deliver_now
        setup.reminder_sent_to << user.id
      end
      setup.reminder_sent_at = Time.zone.now
      setup.save
    end

    puts "Done. Sent #{r_count} reminders for #{s_count} setups."

    # TEMP logging HACK
    LoggerMailer.notify(OauthUser.first, 'Setup Reminder Job', 'Setup Reminder Job just ran.').deliver_now
  end
end
