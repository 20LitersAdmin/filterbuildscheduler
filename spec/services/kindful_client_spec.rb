# frozen_string_literal: true

require 'rails_helper'

RSpec.describe KindfulClient do
  let(:user1) { build :user }
  let(:client) { KindfulClient.new }
  let(:http_spy) { spy }

  describe 'headers' do
    it 'returns a hash' do
      expect(client.headers.class).to eq Hash
    end

    it 'includes a token' do
      client.headers[:Authorization].include?(client.send(:token))
    end
  end

  describe 'import_transaction' do
    it 'takes transaction data and sends it to Kindful' do
      file = JSON.parse(File.read("#{Rails.root}/spec/fixtures/files/charge_succeeded_spec.json"))
      json = file['data']['object'].deep_symbolize_keys

      arguments = {
        headers: client.headers,
        body: client.contact_w_transaction(json)
      }
      expect(KindfulClient).to receive(:post).with('/imports', arguments).and_return(http_spy)
      client.import_transaction(json)
    end
  end

  describe 'import_user' do
    it 'takes user data and sends it to kindful' do
      arguments = {
        headers: client.headers,
        body: client.contact(user1)
      }
      expect(KindfulClient).to receive(:post).with('/imports', arguments).and_return(http_spy)
      client.import_user(user1)
    end
  end

  describe 'import_user_w_email_note' do
    pending 'takes email data and sends it to Kindful'
  end

  describe 'import_user_w_note' do
    it 'takes registration data and sends it to Kindful' do
      registration = FactoryBot.create(:registration_attended, user: user1)
      arguments = {
        headers: client.headers,
        body: client.contact_w_note(registration)
      }
      expect(KindfulClient).to receive(:post).with('/imports', arguments).and_return(http_spy)
      client.import_user_w_note(registration)
    end
  end

  describe 'email_exists_in_kindful?' do
    it 'asks Kindful production site to check if an email exists' do
      email = 'jondoe@email.com'
      expect(KindfulClient).to receive(:get).with("https://app.kindful.com/api/v1/contacts/email_exist?email=#{email}", { headers: client.send(:live_headers) }).and_return(http_spy)
      client.email_exists_in_kindful?(email)
    end
  end

  describe 'query_organizations' do
    pending 'queries Kindful for several group IDs to retrieve all organizations form Kindful'
  end

  describe 'query_organizations_next' do
    pending 'retrieves the next set of responses from Kindful and adds them to the results'
  end

  describe 'contact' do
    it 'returns a json object from a user object' do
      user1.save
      contact_json = JSON.parse client.contact(user1)
      expect(contact_json['data'][0]['id']).to eq user1.id.to_s
      expect(contact_json['data'][0]['email']).to eq user1.email
    end
  end

  describe 'contact_w_note' do
    it 'returns a json object from a registration object' do
      user1.save
      registration = FactoryBot.create(:registration_attended, user: user1)
      contact_json = JSON.parse client.contact_w_note(registration)
      expect(contact_json['data'][0]['id']).to eq user1.id.to_s
      expect(contact_json['data'][0]['note_id']).to eq registration.id.to_s
    end
  end

  describe 'contact_with_transaction' do
    it 'returns a Kindful note json object from a Stripe payment json object' do
      file = JSON.parse File.read("#{Rails.root}/spec/fixtures/files/charge_succeeded_spec.json")
      json = file['data']['object'].deep_symbolize_keys
      contact_json = JSON.parse client.contact_w_transaction(json)

      expect(contact_json['data'][0]['first_name']).to eq json[:metadata][:first_name]
    end
  end

  describe 'organizations_query' do
    pending 'returns a Kindful query json string'
  end

  describe 'organizations_next_page' do
    pending 'returns a Kindful next page query string'
  end

  private

  describe 'token' do
    it 'retrieves a token from the credentials' do
      expect(Rails.application).to receive(:credentials).and_return(spy)
      client.send(:token)
    end
  end

  describe 'live_headers' do
    it 'retrieves the production token' do
      live_header = client.send(:live_headers)
      expect(live_header[:Authorization]).to include(Rails.application.credentials.kf_filterbuild_token)
    end
  end
end
