# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmailSyncJob, type: :job do
  let(:job) { EmailSyncJob.new }
  let(:oauth_user) { create :oauth_user }
  let(:oauth_user2) { create :oauth_user }
  let(:gmail_instance) { instance_double GmailClient }
  let(:oau) { create :oauth_user }

  before do
    # create an OauthUser for LoggerMailer.notify
    oau
  end

  it 'queues as email_sync' do
    expect(job.queue_name).to eq 'email_sync'
  end

  describe '#perform' do
    it 'calls OauthUser.to_sync' do
      allow(OauthUser).to receive(:to_sync).and_return(OauthUser.all)

      expect(OauthUser).to receive(:to_sync)

      job.perform
    end

    it 'calls GmailClient' do
      allow(GmailClient).to receive(:new).and_return(gmail_instance)
      allow(gmail_instance).to receive(:oauth_fail).and_return(nil)
      allow(gmail_instance).to receive(:batch_get_latest_messages).and_return(true)
      oauth_user
      oauth_user2

      expect(GmailClient).to receive(:new).twice

      expect(gmail_instance).to receive(:batch_get_latest_messages).twice

      job.perform
    end

    it 'updates the OauthUser.last_email_sync record' do
      allow(GmailClient).to receive(:new).and_return(gmail_instance)
      allow(gmail_instance).to receive(:oauth_fail).and_return(nil)
      allow(gmail_instance).to receive(:batch_get_latest_messages).and_return(true)
      oauth_user

      expect(oauth_user.last_email_sync).to eq nil

      job.perform

      expect(oauth_user.reload.last_email_sync).not_to eq nil
    end

    it 'destroys stale emails' do
      allow(GmailClient).to receive(:new).and_return(gmail_instance)
      allow(gmail_instance).to receive(:oauth_fail).and_return(nil)
      allow(gmail_instance).to receive(:batch_get_latest_messages).and_return(true)
      oauth_user

      allow(Email).to receive_message_chain(:stale, :size)

      expect(Email).to receive_message_chain(:stale, :destroy_all)

      job.perform
    end
  end
end
