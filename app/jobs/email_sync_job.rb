# frozen_string_literal: true

# =====> Hello, Interviewers!
# Business case: automatically create a note on a donor's profile when
# matching emails are sent/receieved from OAuth user's email accounts
#
# This job is run by Sidekiq at 4am everyday.
# It grabs all emails from an OAuth-verified user's account
# in a 24-hour period and creates note records in our donor CRM
# for any matches by email.

require 'sidekiq-scheduler'

class EmailSyncJob < ApplicationJob
  queue_as :email_sync

  def perform(*_args)
    puts 'Starting Email Sync'

    before = Date.today.strftime('%Y/%m/%d')
    after = Date.yesterday.strftime('%Y/%m/%d')

    puts "-+ Syncing emails after:#{after} before:#{before}"
    log_msg = "-+ Syncing emails after:#{after} before:#{before}"

    OauthUser.to_sync.each do |o|
      a_size = Email.all.size
      a_sent = Email.synced.size

      gc = GmailClient.new(o)

      # bail if Oauth failure
      if gc.oauth_fail.present?
        puts "-+-+ #{o.name} FAIL: #{gc.oauth_fail}"
        log_msg += "\n-+-+ #{o.name} FAIL: #{gc.oauth_fail}"
        next
      end

      gc.batch_get_latest_messages(after:, before:)

      b_size = Email.all.size - a_size
      b_sent = Email.synced.size - a_sent

      o.update_column(:last_email_sync, Time.now)

      puts "-+-+ Results for #{o.name}: Created #{b_size} emails. Synced #{b_sent} interactions to CRM"
      log_msg += "\n-+-+ Results for #{o.name}: Created #{b_size} emails. Synced #{b_sent} interactions to CRM"
    end

    e_size = Email.stale.size
    Email.stale.destroy_all
    puts "-+ Removed #{e_size} stale emails."
    log_msg += "\n-+ Removed #{e_size} stale emails."

    puts 'Done.'

    # TEMP logging HACK
    LoggerMailer.notify(OauthUser.first, 'Email Sync Job', "Rough log of events:\n#{log_msg}")
  end
end
