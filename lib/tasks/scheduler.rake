# frozen_string_literal: true

# Unused by Railway, using sidekiq-scheduler instead
# SEE /sidekiq.yml

# desc 'Email Scheduling Daemon'
# task send_reminders: :environment do
#   RegistrationReminderJob.perform_now
#   SetupReminderJob.perform_now
# end

# task sync_emails: :environment do
#   EmailSyncJob.perform_now
# end

# task sync_organizations: :environment do
#   puts 'Checking to see if Organizations need to be synced'
#   if Date.today.day == 1
#     KindfulOrganizationSyncJob.perform_now
#   else
#     puts 'Nope. Not the 1st of the month.'
#   end
# end
