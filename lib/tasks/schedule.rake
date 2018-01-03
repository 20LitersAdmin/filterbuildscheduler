desc "Reminder Email Scheduling Daemon"
task schedule: :environment do
  Delayed::Job.all.each do |job|
    job.destroy if job.name == "RegistrationReminderJob"
  end

  Delayed::Job.enqueue(RegistrationReminderJob.new, cron: '42 13 * * *' )
end