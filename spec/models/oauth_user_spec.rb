# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OauthUser, type: :model do
  let(:oauth_user) { create :oauth_user }

  describe 'must be valid' do
    let(:dup_oauth_id) { build :oauth_user, oauth_id: oauth_user.oauth_id }
    let(:dup_token) { build :oauth_user, oauth_token: oauth_user.oauth_token }

    it 'in order to save' do
      expect(dup_oauth_id.valid?).to eq false
      expect(dup_oauth_id.errors.messages[:oauth_id][0]).to eq 'has already been taken'

      expect(dup_token.valid?).to eq false
      expect(dup_token.errors.messages[:oauth_token][0]).to eq 'has already been taken'
    end
  end

  describe 'OauthUser#from_onmiauth(auth)' do
    let(:oauth_response) { JSON.parse(File.read("#{Rails.root}/spec/fixtures/files/omniauth_oauth_spec.json"), object_class: OpenStruct) }

    context 'when the oauth_user already exists' do
      let(:already_existing_oauth) { create :oauth_user, email: 'chip@20liters.org' }

      it 'updates the record' do
        already_existing_oauth

        expect(already_existing_oauth.name).not_to eq 'Chip Kragt'

        expect { OauthUser.from_omniauth(oauth_response) }
          .not_to change { OauthUser.all.size }

        expect(already_existing_oauth.reload.name).to eq 'Chip Kragt'
      end
    end

    it 'creates a new OauthUser using data received from OmniAuth' do
      expect { OauthUser.from_omniauth(oauth_response) }
        .to change { OauthUser.all.size }
        .by(1)

      expect(OauthUser.last.name).to eq 'Chip Kragt'
    end
  end

  describe '#authorization' do
    it 'initializes Google::APIClient::ClientSecrets' do
      allow(Google::APIClient::ClientSecrets).to receive(:new).and_call_original

      expect(Google::APIClient::ClientSecrets).to receive(:new)

      oauth_user.authorization
    end
  end

  describe '#oauth_expired' do
    it 'compares oauth_expires_at with the current time' do
      oauth_user.oauth_expires_at = Time.now + 5.minutes
      expect(oauth_user.oauth_expired?).to eq false

      oauth_user.oauth_expires_at = Time.now - 5.minutes
      expect(oauth_user.oauth_expired?).to eq true
    end
  end

  describe '#oauth_remaining' do
    it 'returns an integer representing minutes' do
      oauth_user.oauth_expires_at = Time.now + 5.minutes

      expect(oauth_user.oauth_remaining).to eq ((oauth_user.oauth_expires_at - Time.now) / 1.minutes).to_i
    end
  end

  describe '#email_service' do
    before :each do
      allow(oauth_user).to receive(:oauth_expired?).and_return(false)
    end

    it 'clears out any error messages from previous runs' do
      oauth_user.update(oauth_error_message: 'There was an error')

      expect(oauth_user).to receive(:update_columns).with(oauth_error_message: nil)

      oauth_user.email_service
    end

    it 'initializes Google::Apis::GmailV1::GmailService' do
      allow(Google::Apis::GmailV1::GmailService).to receive(:new).and_call_original

      expect(Google::Apis::GmailV1::GmailService).to receive(:new)

      oauth_user.email_service
    end
  end

  # response = { 'expires_in': Time.now + 20.minutes, 'access_token': 's0m3-rand0m-num8ers' }
  # service_double = instance_double(Google::Apis::GmailV1::GmailService)
  # allow(oauth_user).to receive(:email_service).and_return(service_double)

  # authorization_double = instance_double(Signet::OAuth2::Client)
  # allow(service_double).to receive(:authorization).and_return(authorization_double)
  # allow(authorization_double).to receive(:refresh!).and_return(response)
  describe '#refresh_authorization!' do
    context 'if @service is nil' do
      it 'calls #email_service' do
        allow(oauth_user).to receive(:email_service).and_call_original
        expect(oauth_user).to receive(:email_service)

        oauth_user.refresh_authorization!
      end
    end

    it 'updates the oauth_users token and expirey info' do
      response = { 'expires_in': 86_400, 'access_token': 's0m3-rand0m-num8ers' }.as_json
      allow_any_instance_of(Google::Apis::GmailV1::GmailService).to receive_message_chain(:authorization, :refresh!).and_return(response)
      allow(oauth_user).to receive(:oauth_expired?).and_return(false)

      expect(oauth_user)
        .to receive(:update_columns)
        .with(oauth_token: 's0m3-rand0m-num8ers', oauth_expires_at: anything)

      oauth_user.refresh_authorization!
    end
  end

  describe '#details' do
    it 'returns a JSON object from the record' do
      expect(oauth_user.details.class).to eq Hash
      expect(oauth_user.details.keys).to include :sync_emails
      expect(oauth_user.details.keys).to include :oauth_id
      expect(oauth_user.details.keys).to include :oauth_expires_at
      expect(oauth_user.details.keys).to include :last_email_sync
      expect(oauth_user.details.keys).to include :manual_query
      expect(oauth_user.details.keys).to include :oauth_error_message
    end
  end

  describe '#quick_details' do
    it 'returns a JSON object from the record' do
      expect(oauth_user.quick_details.class).to eq Hash
      expect(oauth_user.quick_details.keys).to include :sync_emails
      expect(oauth_user.quick_details.keys).to include :last_email_sync
      expect(oauth_user.quick_details.keys).to include :oauth_error_message
    end
  end
end
