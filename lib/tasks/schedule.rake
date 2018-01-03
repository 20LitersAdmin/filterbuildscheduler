desc "Reminder Email Scheduling Daemon"
task schedule: :environment do
  Delayed::Job.all.each do |job|
    job.destroy if job.name == "RegistrationReminderJob" || job.name == "ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper"
  end

  Delayed::Job.enqueue(RegistrationReminderJob.new, cron: '00 15 * * *' )
end