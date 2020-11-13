# frozen_string_literal: true

class EmailSyncJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    puts '-+ Cleaning up the EmailSyncJob list'
    Delayed::Job.all.each do |job|
      job.destroy if job.queue == 'email_sync'
    end

    before = Date.yesterday.strftime('%Y/%m/%d')
    after = (Date.yesterday - 1.day).strftime('%Y/%m/%d')

    puts "-+ Syncing emails after:#{after} before:#{before}"

    OauthUsers.all.each do |o|
      a_size = Email.all.size
      a_sent = Email.synced.size
      puts "-+-+ Syncing for #{o.name}"

      gc = GmailClient.new(o)
      gc.batch_get_latest_messages(after: after, before: before)

      b_size = Email.all.size - a_size
      b_sent = Email.synced.size - a_sent

      puts "-+-+ Results for #{o.name}:"
      puts "-+-+-+ Created #{b_size} emails"
      puts "-+-+-+ Synced #{b_sent} notes to Kindful"
    end
  end
end
