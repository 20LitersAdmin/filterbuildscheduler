# frozen_string_literal: true

desc 'Email Scheduling Daemon'
task send_reminders: :environment do
  puts 'Scheduling Registration Reminders'
  RegistrationReminderJob.perform_now
  puts 'Done.'
end

task sync_emails: :environment do
  puts 'Scheduling Email Syncs'
  EmailSyncJob.perform_now
  puts 'Done.'
end
