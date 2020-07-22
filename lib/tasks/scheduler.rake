# frozen_string_literal: true

desc 'Email Scheduling Daemon'
task send_reminders: :environment do
  puts 'Scheduling registration reminders'
  RegistrationWorker.set(cron: '49 16 * * *').perform_later
  puts 'Done'
end

# task send_report: :environment do
#   puts 'Scheduling monthly report'
#   ReportJob.set(cron: '30 7 1 * *').perform_later
#   puts 'Done'
# end
