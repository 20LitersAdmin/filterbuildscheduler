# frozen_string_literal: true

require 'rails_helper'

RSpec.describe KindfulClient do
  let(:user1) { build :user }
  let(:client) { KindfulClient.new }

  describe 'import_user' do
    it 'takes user data and sends it to kindful' do
      http_spy = spy

      arguments = {
        headers: client.headers,
        body: client.contact(user1)
      }
      expect(KindfulClient).to receive(:post).with('/imports', arguments).and_return(http_spy)
      client.import_user(user1)
    end
  end

  describe 'headers' do
    it 'returns a hash' do
      expect(client.headers.class).to eq Hash
    end

    pending 'includes a token' do
      # byebug
    end
  end

  describe 'import_user_w_note' do
    pending
  end

  describe 'import_transaction' do
    pending
  end

  describe 'token' do
    pending
  end

  describe 'headers' do
    pending
  end

  describe 'contact' do
    pending
  end

  describe 'contact_w_note' do
    pending
  end

  describe 'contact_with_transaction' do
    pending
  end
end
