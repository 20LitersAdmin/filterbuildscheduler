# frozen_string_literal: true

desc 'Email Scheduling Daemon'
task send_reminders: :environment do
  puts 'Scheduling Registration Reminders'
  RegistrationReminderJob.perform_now
  puts 'Done.'
  puts 'Scheduling Setup Reminders'
  SetupReminderJob.perform_now
  puts 'Done.'
end

task sync_emails: :environment do
  puts 'Scheduling Email Syncs'
  EmailSyncJob.perform_now
  puts 'Done.'
end

task sync_organizations: :environment do
  puts 'Checking to see if Organizations need to be synced'
  if Date.today.day == 1
    puts 'Syncing Organizations'
    KindfulClient.new.query_organizations
    puts 'Done.'
  else
    puts 'Nope. Not the 1st of the month.'
  end
end
