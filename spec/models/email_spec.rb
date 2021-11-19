# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Email, type: :model do
  let(:oauth_user) { create :oauth_user, email: 'chip@20liters.org' }
  let(:email) { create :email, oauth_user: oauth_user }

  describe 'must be valid' do
    let(:no_message_id) { build :email, message_id: nil }
    let(:dup_message_id) { build :email, message_id: email.message_id }
    let(:no_gmail_id) { build :email, gmail_id: nil }
    let(:dup_gmail_id) { build :email, gmail_id: email.gmail_id }
    let(:no_from) { build :email, from: nil }
    let(:no_to) { build :email, to: nil }
    let(:internal_email) { build :email, to: ['chip@20liters.org'], from: ['amanda@twentyliters.com'] }

    it 'in order to save' do
      expect(no_message_id.valid?).to eq false
      expect(no_message_id.errors.messages[:message_id]).to eq ['can\'t be blank']

      expect(dup_message_id.valid?).to eq false
      expect(dup_message_id.errors.messages[:message_id]).to eq ['has already been taken']

      expect(no_gmail_id.valid?).to eq false
      expect(no_gmail_id.errors.messages[:gmail_id]).to eq ["can't be blank"]

      expect(dup_gmail_id.valid?).to eq false
      expect(dup_gmail_id.errors.messages[:gmail_id]).to eq ['has already been taken']

      expect(no_from.valid?).to eq false
      expect(no_from.errors.messages[:from]).to eq ["can't be blank"]

      expect(no_to.valid?).to eq false
      expect(no_to.errors.messages[:to]).to eq ["can't be blank"]

      expect(internal_email.valid?).to eq false
      expect(internal_email.errors.messages[:from]).to eq ['Internal Emails only!']
    end

    describe 'Email#from_gmail' do
      let(:oauth_user) { create :oauth_user }
      let(:response) { JSON.parse(File.read("#{Rails.root}/spec/fixtures/files/gmail_message_spec.json"), object_class: OpenStruct) }

      context 'when message_id is nil' do
        it 'returns nil' do
          response_no_id = JSON.parse(File.read("#{Rails.root}/spec/fixtures/files/gmail_message_no_id_spec.json"), object_class: OpenStruct)
          # response = JSON.parse(File.read("#{Rails.root}/spec/fixtures/files/gmail_message_spec.json"), object_class: OpenStruct)

          expect(Email.from_gmail(response_no_id, 'email body string', oauth_user)).to eq nil
        end
      end

      context 'when email message already exists' do
        let(:fixture_email) { create :email, message_id: 'CAG4LXW=jEzKkfOLnE5jOSo7ertC=gAj-6GKE1qO=P8KB19fake@mail.gmail.com' }

        it 'returns the email object' do
          fixture_email

          expect(Email.from_gmail(response, 'body as string', oauth_user)).to eq fixture_email
        end
      end

      it 'creates an email from a Gmail response' do
        expect { Email.from_gmail(response, 'body as string', oauth_user) }
          .to change { Email.all.size }
          .from(0).to(1)
      end
    end
  end

  describe '#send_to_kindful' do
    before :each do
      kf_success_json = { status: 'success' }.as_json
      allow_any_instance_of(KindfulClient).to receive(:email_exists_in_kindful?).and_return(true)

      allow_any_instance_of(KindfulClient).to receive(:import_company_w_email_note).and_return(kf_success_json)

      allow_any_instance_of(KindfulClient).to receive(:import_user_w_email_note).and_return(kf_success_json)
    end

    it 'initializes KindfulClient' do
      expect(KindfulClient).to receive(:new).and_call_original

      email.send_to_kindful
    end

    it 'checks each email for an Organization match' do
      expect(Organization).to receive(:find_by).once.and_call_original

      email.send_to_kindful
    end

    context 'when the email is found in Kindful and Kindful API responds successfully' do
      it 'updates itself' do
        expect(email).to receive(:update_columns)

        email.send_to_kindful
      end
    end
  end

  describe 'Email#cleanup_text' do
    context 'when text is nil' do
      it 'returns nil' do
        expect(Email.cleanup_text(nil)).to eq nil
      end
    end

    it 'removes common email symbol garbage' do
      text = '>>this string \has\ "garbage" I dont want.'

      expect(Email.cleanup_text(text)).to eq 'this string has garbage I dont want.'
    end
  end

  describe 'Email#email_address_from_text' do
    context 'when text is nil' do
      it 'returns nil' do
        expect(Email.email_address_from_text(nil)).to eq nil
      end
    end

    it 'finds a valid email address in a string' do
      text = 'this text has@nemail.address in it'

      expect(Email.email_address_from_text(text)).to eq ['has@nemail.address']
    end
  end

  describe '#sync_msg' do
    context 'when email was not sent_to_kindful' do
      it 'returns a specific message' do
        expect(email.sync_msg).to eq 'Not synced. No contact match.'
      end
    end

    it 'returns a specific message' do
      email.sent_to_kindful_on = Time.now
      email.matched_emails = ['matched@email.com', 'also@matched-email.com']

      expect(email.sync_msg).to eq "Synced with matched@email.com, also@matched-email.com at #{email.sent_to_kindful_on.strftime('%-m/%-d/%y %l:%M %P')}"
    end
  end

  describe '#sync_banner_color' do
    context 'when email was not sent_to_kindful' do
      it 'returns "warning"' do
        expect(email.sync_banner_color).to eq 'warning'
      end
    end

    context 'when email was sent_to_kindful' do
      it 'returns "success"' do
        email.sent_to_kindful_on = Time.now

        expect(email.sync_banner_color).to eq 'success'
      end
    end
  end

  describe '#synced?' do
    context 'when sent_to_kindful_on is present' do
      it 'returns true' do
        email.sent_to_kindful_on = Time.now

        expect(email.synced?).to eq true
      end
    end

    context 'when sent_to_kindful_on is not present' do
      it 'returns false' do
        expect(email.synced?).to eq false
      end
    end
  end

  describe '#synced_data' do
    it 'returns a hash of specific attributes' do
      expect(email.synced_data.class).to eq Hash

      expect(email.synced_data).to include 'id'
      expect(email.synced_data).to include 'sent_to_kindful_on'
      expect(email.synced_data).to include 'kindful_job_id'
      expect(email.synced_data).to include 'gmail_id'
      expect(email.synced_data).to include 'message_id'
    end
  end

  describe '#deny_internal_messages' do
    it 'is already tested through validity' do
      expect(true).to eq true
    end
  end

  describe '#target_emails' do
    context 'when the oauth_user sent the message' do
      it 'returns an array of emails from the "to" field' do
        expect(email.target_emails).to eq [[email.to[0], 'Received Email']]
      end
    end

    context 'when the oauth_user received the message' do
      let(:email_to) { build :email_to, oauth_user: oauth_user }

      it 'returns an array of emails from the "from" field' do
        expect(email_to.target_emails).to eq [[email_to.from[0], 'Sent Email']]
      end
    end
  end
end
