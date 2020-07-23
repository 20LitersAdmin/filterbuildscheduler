# frozen_string_literal: true

desc 'Email Scheduling Daemon'
task send_reminders: :environment do
  puts 'Scheduling registration reminders'
  RegistrationReminderJob.set(cron: '49 16 * * *').perform_later
  puts 'Done'
end
