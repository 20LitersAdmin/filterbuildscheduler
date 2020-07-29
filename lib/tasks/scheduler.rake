# frozen_string_literal: true

desc 'Email Scheduling Daemon'
task send_reminders: :environment do
  puts 'Scheduling registration reminders'
  RegistrationReminderJob.delay(queue: 'registration_reminder', cron: '49 16 * * *')
  puts 'Done'
end
