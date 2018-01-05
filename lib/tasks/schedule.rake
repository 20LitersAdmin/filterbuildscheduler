desc "Reminder Email Scheduling Daemon"
task schedule: :environment do
  Delayed::Job.all.each do |job|
    job.destroy if job.name == "RegistrationReminderJob" || job.name == "ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper"
  end

  RegistrationReminderJob.set(cron: '49 16 * * *').perform_later
end
