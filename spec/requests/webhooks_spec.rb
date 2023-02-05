# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Webhooks', type: :request do
  context 'successful post from CauseVox' do
    let(:data) { JSON.parse(file_fixture('charge_succeeded_spec.json').read) }
    let(:bloom_double) { instance_double BloomerangClient }

    before :each do
      allow(BloomerangClient).to receive(:new).with(:causevoxsync).and_return(bloom_double)
      allow(bloom_double).to receive(:create_from_causevox).and_return true
    end

    it 'responds with 200 OK' do
      post stripe_webhook_path, params: data
      expect_status :ok
    end

    it 'creates a StripeCharge object from the data' do
      allow(StripeCharge).to receive(:new)

      expect(StripeCharge).to receive(:new)
      post stripe_webhook_path, params: data
    end

    it 'sends the transaction and user to BloomerangClient' do
      expect(BloomerangClient).to receive(:new).with(:causevoxsync)
      post stripe_webhook_path, params: data
    end
  end

  context 'Post from anyone else' do
    before :each do
      data = { 'data': { 'object': { 'application': 'not_causevox' } } }
      post stripe_webhook_path, params: data
    end

    it 'responds with 200 OK' do
      expect_status :ok
    end

    it 'doesn\'t pass to BloomerangClient' do
      expect(BloomerangClient).not_to receive(:new).with(:causevoxsync)
    end
  end
end
