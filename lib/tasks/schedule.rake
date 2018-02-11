desc "Email Scheduling Daemon"
task schedule: :environment do
  Delayed::Job.all.each do |job|
    job.destroy if job.name == "RegistrationReminderJob" || job.name == "ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper" || job.name == "ReportJob"
  end

  RegistrationReminderJob.set(cron: '49 16 * * *').perform_later
  ReportJob.set(cron: '30 7 1 * *').perform_later
end
