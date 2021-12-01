# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GmailClient do
  let(:oauth_user) { create :oauth_user }
  let(:client) { GmailClient.new(oauth_user) }
  let(:http_spy) { spy }
  let(:gmail_instance) { instance_double(Google::Apis::GmailV1::GmailService) }
  let(:email_response) { JSON.parse(File.read("#{Rails.root}/spec/fixtures/files/gmail_message_spec.json"), object_class: OpenStruct) }
  let(:email_error) { Google::Apis::ClientError.new('notFound: Requested entity was not found.') }
  let(:paged_json) { JSON.parse(File.read("#{Rails.root}/spec/fixtures/files/gmail_paged_response_spec.json"), object_class: OpenStruct) }
  let(:query) { "after:#{Date.yesterday.iso8601} before:#{Date.today.iso8601}" }

  it 'stores accessible variables' do
    expect(client.standard_fields.class).to eq String
    expect(client.service.class).to eq Google::Apis::GmailV1::GmailService
    expect(client.user.class).to eq OauthUser
    expect(client.skipped_ids.class).to eq Array
    expect(client.fails.class).to eq Array
    expect(client.oauth_fail.class).to eq String
  end

  describe '#batch_get_latest_messages(:after, :before)' do
    let(:after) { Date.yesterday.iso8601 }
    let(:before) { Date.today.iso8601 }

    it 'passes the vars to batch_get_queried_messages' do
      expect(client).to receive(:batch_get_queried_messages).with(query: query)

      client.batch_get_latest_messages(after: after, before: before)
    end
  end

  describe '#batch_get_messages(message_ids)' do
    before do
      allow(oauth_user).to receive(:refresh_authorization!).and_return(true)
      allow(oauth_user).to receive(:email_service).and_return(gmail_instance)
      allow(gmail_instance).to receive(:batch).and_yield(gmail_instance)
      allow(gmail_instance).to receive(:get_user_message)
    end
    it 'gets messages in batches' do
      expect(client.service).to receive(:batch)

      client.batch_get_messages([1, 2])
    end

    it 'calls GmailService.get_user_message' do
      allow(gmail_instance).to receive(:get_user_message).and_yield(email_response, nil)

      expect(gmail_instance).to receive(:get_user_message)

      client.batch_get_messages([1, 2, 3, 4])
    end

    context 'when a response is returned without an error' do
      it 'calls Email.from_gmail' do
        allow(gmail_instance).to receive(:get_user_message).and_yield(email_response, nil)

        allow(Email).to receive(:from_gmail).and_return(true)

        expect(Email).to receive(:from_gmail).exactly(4).times

        client.batch_get_messages([1, 2, 3, 4])
      end
    end

    context 'when an error is returned' do
      it 'saves the ID, and records a failure message' do
        allow(gmail_instance).to receive(:get_user_message).and_yield(nil, email_error)

        expect(client.skipped_ids.empty?).to eq true

        client.batch_get_messages([1, 2, 3, 4])

        expect(client.skipped_ids.any?).to eq true
        expect(client.fails.size).to eq 4
      end
    end
  end

  describe '#batch_get_queried_messages(:query)' do
    before do
      allow(client).to receive(:list_queried_messages).with(query: query).and_return(paged_json)
      allow(client).to receive(:get_message).and_return(true)
      allow(client).to receive(:batch_get_messages).and_return(true)
    end

    it 'passes the query to list_queried_messages' do
      expect(client).to receive(:list_queried_messages).with(query: query)
      client.batch_get_queried_messages(query: query)
    end

    it 'passes the message ids to batch_get_messages' do
      expect(client).to receive(:batch_get_messages)
      client.batch_get_queried_messages(query: query)
    end
  end

  describe '#find_body' do
    it 'loops down through the message parts to find the part that has body.data' do
      expect(client.body_data).to eq nil

      client.find_body(email_response.payload.parts[0], 'text/plain')

      expect(client.body_data).not_to eq nil
    end

    it 'sanitizes the body data' do
      allow(ActionView::Base).to receive_message_chain(:full_sanitizer, :sanitize, :squish)

      expect(ActionView::Base).to receive_message_chain(:full_sanitizer, :sanitize)

      client.find_body(email_response.payload.parts[0], 'text/plain')
    end
  end

  describe '#get_message' do
    before do
      allow(oauth_user).to receive(:refresh_authorization!).and_return(true)
      allow(oauth_user).to receive(:email_service).and_return(gmail_instance)
    end
    it 'calls GmailService.get_user_message' do
      allow(gmail_instance).to receive(:get_user_message).and_return(email_response)

      expect(gmail_instance).to receive(:get_user_message)

      client.get_message('12345')
    end

    context 'when response is nil' do
      it 'records the ID as skipped and a fail' do
        allow(gmail_instance).to receive(:get_user_message).and_return(nil)

        expect(client.skipped_ids.any?).to eq false
        expect(client.fails.any?).to eq false

        client.get_message('12345')

        expect(client.skipped_ids.any?).to eq true
        expect(client.fails.any?).to eq true
      end
    end

    context 'when response is present' do
      it 'calls Email.from_gmail' do
        allow(gmail_instance).to receive(:get_user_message).and_return(email_response)

        allow(Email).to receive(:from_gmail).and_return(true)

        expect(Email).to receive(:from_gmail).once

        client.get_message('12345')
      end
    end
  end

  describe '#list_latests_messages' do
    it 'passes the variables onto list_queried_messages' do
      allow(client).to receive(:list_queried_messages)

      expect(client).to receive(:list_queried_messages)

      client.list_latest_messages(after: Date.yesterday, before: Date.today)
    end
  end

  describe '#list_queried_messages' do
    before do
      allow(oauth_user).to receive(:refresh_authorization!).and_return(true)
      allow(oauth_user).to receive(:email_service).and_return(gmail_instance)
    end

    it 'calls GmailService.fetch_all' do
      allow(gmail_instance).to receive(:fetch_all)
      expect(gmail_instance).to receive(:fetch_all)

      client.list_queried_messages(query: query)
    end

    it 'calls GmailService.list_user_messages' do
      allow(gmail_instance).to receive(:fetch_all).and_yield('t0k3n')
      allow(gmail_instance).to receive(:list_user_messages).with(anything)

      expect(gmail_instance).to receive(:list_user_messages).with('me', include_spam_trash: false, q: query, page_token: 't0k3n')

      client.list_queried_messages(query: query)
    end
  end

  describe '#refresh_authorization!' do
    it 'calls refresh_authorization on the OauthUser' do
      allow(oauth_user).to receive(:refresh_authorization!)

      expect(oauth_user).to receive(:refresh_authorization!)

      client.refresh_authorization!
    end
  end

  describe '#see_message' do
    it 'calls GmailService.get_user_message' do
      allow(oauth_user).to receive(:refresh_authorization!).and_return(true)
      allow(oauth_user).to receive(:email_service).and_return(gmail_instance)
      allow(gmail_instance).to receive(:get_user_message)

      expect(gmail_instance).to receive(:get_user_message).with('me', 'Th1sI0', fields: client.standard_fields)

      client.see_message('Th1sI0')
    end
  end

  describe '#trim_response' do
    context 'without a provided response' do
      it 'returns nil' do
        expect(client.trim_response(nil)).to eq nil
      end
    end

    it 'strips some headers out' do
      original_header_names = email_response.payload.headers.map { |h| h.name.downcase }

      expect(original_header_names).to include 'mime-version'
      expect(original_header_names).to include 'date'
      expect(original_header_names).to include 'message-id'
      expect(original_header_names).to include 'subject'
      expect(original_header_names).to include 'from'
      expect(original_header_names).to include 'to'
      expect(original_header_names).to include 'content-type'

      client.trim_response(email_response)

      header_names = email_response.payload.headers.map { |h| h.name.downcase }

      expect(header_names).not_to include 'mime-version'
      expect(header_names).to include 'date'
      expect(header_names).to include 'message-id'
      expect(header_names).to include 'subject'
      expect(header_names).to include 'from'
      expect(header_names).to include 'to'
      expect(header_names).not_to include 'content-type'
    end

    it 'calls ActionView::Base.full_sanitizer' do
      # either right away, or via :find_body
      allow(ActionView::Base).to receive_message_chain(:full_sanitizer, :sanitize, :squish).and_return 'clean string, no worries'

      expect(ActionView::Base).to receive_message_chain(:full_sanitizer, :sanitize, :squish)

      client.trim_response(email_response)
    end

    it 'sets @body_data' do
      expect(client.body_data).to eq nil

      client.trim_response(email_response)

      expect(client.body_data).not_to eq nil
    end
  end
end
