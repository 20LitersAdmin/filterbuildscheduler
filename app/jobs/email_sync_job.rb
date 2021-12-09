# frozen_string_literal: true

class EmailSyncJob < ApplicationJob
  queue_as :email_sync

  def perform(*_args)
    before = Date.today.strftime('%Y/%m/%d')
    after = Date.yesterday.strftime('%Y/%m/%d')

    puts "-+ Syncing emails after:#{after} before:#{before}"

    OauthUser.to_sync.each do |o|
      a_size = Email.all.size
      a_sent = Email.synced.size

      gc = GmailClient.new(o)

      # bail if Oauth failure
      if gc.oauth_fail.present?
        puts "-+-+ #{o.name} FAIL: #{gc.oauth_fail}"
        next
      end

      gc.batch_get_latest_messages(after: after, before: before)

      b_size = Email.all.size - a_size
      b_sent = Email.synced.size - a_sent

      o.update_column(:last_email_sync, Time.now)

      puts "-+-+ Results for #{o.name}: Created #{b_size} emails. Synced #{b_sent} notes to Kindful"
    end

    e_size = Email.stale.size
    Email.stale.destroy_all
    puts "-+ Removed #{e_size} stale emails."
  end
end
