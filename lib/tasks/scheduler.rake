# frozen_string_literal: true

desc 'Email Scheduling Daemon'
task send_reminders: :environment do
  puts 'Performing Registration Reminders'
  RegistrationReminderJob.perform_now
  puts 'Done.'
end

task sync_emails: :environment do
  puts 'Performing Email Sync'
  EmailSyncJob.perform_now
  puts 'Done.'
end
