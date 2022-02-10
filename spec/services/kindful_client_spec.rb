# frozen_string_literal: true

require 'rails_helper'

RSpec.describe KindfulClient do
  let(:user1) { build :user }
  let(:client) { KindfulClient.new }
  let(:http_spy) { spy }

  it 'stores accessible variables' do
    expect(client.results.class).to eq Array
    expect(client.env).to eq 'sandbox'
  end

  describe 'set_host' do
    context 'when @env == production' do
      before :each do
        client.env = 'production'
      end

      it 'sets @host to the production URL' do
        client.set_host
        expect(client.instance_variable_get(:@host)).to eq 'https://app.kindful.com/api/v1/'
      end
    end

    context 'when @env != production' do
      it 'sets @host to the sandbox URL' do
        client.set_host
        expect(client.instance_variable_get(:@host)).to eq 'https://app-sandbox.kindful.com/api/v1'
      end
    end
  end

  describe 'import_transaction' do
    it 'takes transaction data and sends it to Kindful' do
      file = JSON.parse(File.read("#{Rails.root}/spec/fixtures/files/charge_succeeded_spec.json"))
      json = file['data']['object'].deep_symbolize_keys

      arguments = {
        headers: client.__send__(:headers),
        body: client.contact_w_transaction(json)
      }
      expect(KindfulClient).to receive(:post).with(client.import_host, arguments).and_return(http_spy)
      client.import_transaction(json)
    end
  end

  describe 'import_user' do
    it 'takes user data and sends it to kindful' do
      arguments = {
        headers: client.__send__(:headers),
        body: client.contact(user1)
      }
      expect(KindfulClient).to receive(:post).with(client.import_host, arguments).and_return(http_spy)
      client.import_user(user1)
    end
  end

  describe 'import_company_w_email_note' do
    it 'takes email data from a company and sends it to Kindful' do
      company = FactoryBot.build(:organization)
      oauth_user = FactoryBot.create(:oauth_user)
      email = FactoryBot.build(:email, oauth_user_id: oauth_user.id, to: [company.email])
      allow(email).to receive(:send_to_kindful).and_return(email)
      email.save
      direction = 'Received Email'
      arguments = {
        headers: client.__send__(:headers),
        body: client.company_w_email_note(company.email, email, direction, company.company_name)
      }
      expect(KindfulClient).to receive(:post).with(client.import_host, arguments).and_return(http_spy)
      client.import_company_w_email_note(company.email, email, direction, company.company_name)
    end
  end

  describe 'import_user_w_email_note' do
    it 'takes email data and sends it to Kindful' do
      oauth_user = FactoryBot.create(:oauth_user)
      email = FactoryBot.build(:email, oauth_user_id: oauth_user.id, to: [oauth_user.email])
      allow(email).to receive(:send_to_kindful).and_return(email)
      email.save
      direction = 'Received Email'
      arguments = {
        headers: client.__send__(:headers),
        body: client.contact_w_email_note(oauth_user.email, email, direction)
      }
      expect(KindfulClient).to receive(:post).with(client.import_host, arguments).and_return(http_spy)
      client.import_user_w_email_note(oauth_user.email, email, direction)
    end
  end

  describe 'import_user_w_note' do
    it 'takes registration data and sends it to Kindful' do
      registration = FactoryBot.create(:registration_attended, user: user1)
      arguments = {
        headers: client.__send__(:headers),
        body: client.contact_w_note(registration)
      }
      expect(KindfulClient).to receive(:post).with(client.import_host, arguments).and_return(http_spy)
      client.import_user_w_note(registration)
    end
  end

  describe 'email_exists_in_kindful?' do
    it 'asks Kindful production site to check if an email exists' do
      email = 'jondoe@email.com'
      expect(KindfulClient).to receive(:get).with(client.email_host(email), { headers: client.__send__(:live_headers) }).and_return(http_spy)
      client.email_exists_in_kindful?(email)
    end
  end

  describe 'query_organizations' do
    it 'queries Kindful for several group IDs to retrieve all organizations form Kindful' do
      allow(client).to receive(:recreate_organizations).and_return(true)
      file = JSON.parse(File.read("#{Rails.root}/spec/fixtures/files/kindful_org_response.json"))
      response = double(HTTParty::Response)
      allow(response).to receive(:parsed_response).and_return(file)
      arguments = {
        headers: client.__send__(:headers),
        body: client.organizations_query
      }
      expect(KindfulClient).to receive(:post).with(client.query_host, arguments).and_return(response)
      client.query_organizations
    end
  end

  # body methods

  describe 'contact' do
    it 'returns a json object from an email and user object' do
      user1.save
      contact_json = JSON.parse client.contact(user1)
      expect(contact_json['data'][0]['id']).to eq user1.id.to_s
      expect(contact_json['data'][0]['email']).to eq user1.email
    end
  end

  describe 'company_w_email_note' do
    it 'returns a json object from an email and company' do
      company = FactoryBot.create(:organization)
      oauth_user = FactoryBot.create(:oauth_user)
      email = FactoryBot.build(:email, oauth_user_id: oauth_user.id, to: [company.email])
      allow(email).to receive(:send_to_kindful).and_return(email)
      email.save
      direction = 'Received Email'
      company_w_email_note_json = JSON.parse client.company_w_email_note(company.email, email, direction, company.company_name)
      expect(company_w_email_note_json['match_by']['contact']).to eq 'company_name_email'
      expect(company_w_email_note_json['data'][0]['company_name']).to eq company.company_name
      expect(company_w_email_note_json['data'][0]['email']).to eq company.email
      expect(company_w_email_note_json['data'][0]['note_sender_email']).to eq oauth_user.email
    end
  end

  describe 'contact_w_email_note' do
    it 'returns a json object from an email and contact' do
      oauth_user = FactoryBot.create(:oauth_user)
      email = FactoryBot.build(:email, oauth_user_id: oauth_user.id)
      allow(email).to receive(:send_to_kindful).and_return(email)
      email.save
      direction = 'Received Email'
      contact_w_note_json = JSON.parse client.contact_w_email_note(email.to.first, email, direction)
      expect(contact_w_note_json['match_by']['contact']).to eq 'email'
      expect(contact_w_note_json['data'][0]['email']).to eq email.to.first
      expect(contact_w_note_json['data'][0]['note_sender_email']).to eq oauth_user.email
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
    it 'returns a Kindful query json string' do
      org_query = JSON.parse client.organizations_query
      expect(org_query['columns']['contact']).to include('company_name', 'email', 'donor_type')
      expect(org_query['query'][0]['or'].size).to eq 4
    end
  end

  describe 'import_host' do
    it 'returns a string' do
      expect(client.import_host.is_a?(String)).to eq true
    end
  end

  describe 'email_host()' do
    it 'returns a string' do
      expect(client.email_host('test@email.com').is_a?(String)).to eq true
    end
  end

  describe 'query_host' do
    it 'returns a string' do
      expect(client.query_host.is_a?(String)).to eq true
    end
  end

  private

  describe 'recreate_organizations' do
    before :each do
      @file = JSON.parse(File.read("#{Rails.root}/spec/fixtures/files/kindful_org_response.json"))
      client.results = @file['results']
    end

    it 'deletes existing organizations before creating organizations' do
      expect(Organization).to receive(:delete_all)
      client.__send__(:recreate_organizations)
    end
    it 'creates organizations from an array of hashes' do
      expect { client.__send__(:recreate_organizations) }
        .to change { Organization.all.size }
        .from(0)
        .to(@file['results'].size)
    end
  end

  describe 'token' do
    it 'retrieves a token from the credentials' do
      expect(Rails.application).to receive(:credentials).and_return(spy)
      client.__send__(:token)
    end
  end

  describe 'headers' do
    it 'returns a hash' do
      headers = client.__send__(:headers)
      expect(headers.class).to eq Hash
    end

    it 'includes a token' do
      headers = client.__send__(:headers)
      expect(headers[:Authorization]).to include client.__send__(:token)
    end
  end

  describe 'live_headers' do
    it 'retrieves the production token' do
      live_header = client.__send__(:live_headers)
      expect(live_header[:Authorization]).to include(Rails.application.credentials.kf_filterbuild_token)
    end
  end
end
