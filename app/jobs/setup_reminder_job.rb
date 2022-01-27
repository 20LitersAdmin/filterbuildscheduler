# frozen_string_literal: true

class SetupReminderJob < ApplicationJob
  queue_as :setup_reminder

  def perform(*_args)
    setups = Setup.pre_reminders.days_from_now(2)

    setups.each do |setup|
      next if setup.users.empty?

      setup.users.each do |user|
        next if setup.reminder_sent_to.include? user.id

        SetupMailer.remind(setup, user).deliver_now
        setup.reminder_sent_to << user.id
      end
      setup.reminder_sent_at = Time.zone.now
      setup.save
    end
  end
end
