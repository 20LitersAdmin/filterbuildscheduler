# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Email, type: :model do
  let(:oauth_user) { create :oauth_user, email: 'chip@20liters.org' }
  let(:email) { create :email, oauth_user: }

  # Allow created emails to succeed against #deny_unmatced_messages
  let(:bloom_double) { double BloomerangJob }

  before do
    allow(BloomerangJob).to receive(:perform_later).with(:gmailsync, :create_from_email, anything).and_return(bloom_double)
    allow(bloom_double).to receive(:ok?).and_return true
    allow(bloom_double).to receive(:body).and_return ['something']
    allow(bloom_double).to receive(:[]).with('id').and_return 123
  end

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
      expect(no_message_id.errors.messages[:message_id]).to include "can't be blank"

      expect(dup_message_id.valid?).to eq false
      expect(dup_message_id.errors.messages[:message_id]).to include 'has already been taken'

      expect(no_gmail_id.valid?).to eq false
      expect(no_gmail_id.errors.messages[:gmail_id]).to include "can't be blank"

      expect(dup_gmail_id.valid?).to eq false
      expect(dup_gmail_id.errors.messages[:gmail_id]).to include 'has already been taken'

      expect(no_from.valid?).to eq false
      expect(no_from.errors.messages[:from]).to include "can't be blank"

      expect(no_to.valid?).to eq false
      expect(no_to.errors.messages[:to]).to include "can't be blank"

      expect(internal_email.valid?).to eq false
      expect(internal_email.errors.messages[:from]).to include 'Internal Emails only!'
    end
  end

  describe '.cleanup_text' do
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

  describe '.email_address_from_text' do
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

  describe '.from_gmail' do
    let(:response) { JSON.parse(File.read("#{Rails.root}/spec/fixtures/files/gmail_message_spec.json"), object_class: OpenStruct) }

    context 'when message_id is nil' do
      it 'returns nil' do
        response_no_id = JSON.parse(File.read("#{Rails.root}/spec/fixtures/files/gmail_message_no_id_spec.json"), object_class: OpenStruct)

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
      create :constituent, primary_email: 'test@person.me'

      expect { Email.from_gmail(response, 'body as string', oauth_user) }
        .to change { Email.all.size }
        .from(0).to(1)
    end
  end

  describe '#send_to_crm' do
    context 'when sent_to_crm_on is present' do
      it 'returns nil' do
        expect(email.send_to_crm).to eq nil
      end
    end

    context 'when sent_to_crm_on is nil' do
      it 'calls BloomerangJob for each matched_constituents value' do
        email.sent_to_crm_on = nil
        email.matched_constituents = %w[1 2 3]

        expect(BloomerangJob).to receive(:perform_later).exactly(3).times

        email.send_to_crm
      end
    end
  end

  describe '#sync_msg' do
    context 'when email was not sent_to_kindful' do
      it 'returns a specific message' do
        email.sent_to_crm_on = nil

        expect(email.sync_msg).to eq 'Not synced. No contact match.'
      end
    end

    it 'returns a specific message' do
      allow(email).to receive(:constituent_names).and_return('John, Sarah')
      email.sent_to_crm_on = Time.now

      expect(email.sync_msg).to eq "Synced with John, Sarah at #{email.sent_to_crm_on.strftime('%-m/%-d/%y %l:%M %P')}"
    end
  end

  describe '#sync_banner_color' do
    context 'when email was not sent_to_kindful' do
      it 'returns "warning"' do
        email.sent_to_crm_on = nil
        expect(email.sync_banner_color).to eq 'warning'
      end
    end

    context 'when email was sent_to_kindful' do
      it 'returns "success"' do
        expect(email.sync_banner_color).to eq 'success'
      end
    end
  end

  describe '#synced?' do
    context 'when sent_to_crm_on is present' do
      it 'returns true' do
        expect(email.synced?).to eq true
      end
    end

    context 'when sent_to_crm_on is not present' do
      it 'returns false' do
        email.sent_to_crm_on = nil
        expect(email.synced?).to eq false
      end
    end
  end

  describe '#synced_data' do
    it 'returns a hash of specific attributes' do
      expect(email.synced_data.class).to eq Hash

      expect(email.synced_data).to include 'id'
      expect(email.synced_data).to include 'sent_to_crm_on'
      expect(email.synced_data).to include 'crm_job_id'
      expect(email.synced_data).to include 'gmail_id'
      expect(email.synced_data).to include 'message_id'
    end
  end

  describe '#constituent_id_for_email' do
    context 'when a matching Constituent exists' do
      let(:constituent) { create :constituent, primary_email: 'email@mailbox.com' }

      it 'returns the Constituent ID' do
        constituent

        expect(email.constituent_id_for_email('email@mailbox.com')).to eq constituent.id
      end
    end

    context 'when a matching ConstituentEmail exists' do
      let(:constituent) { create :constituent }
      let(:constituent_email) { create :constituent_email, value: 'email@mailbox.com', constituent: }

      it "returns the ConstituentEmail's parent Constituent ID" do
        constituent
        constituent_email

        expect(email.constituent_id_for_email('email@mailbox.com')).to eq constituent.id
      end
    end

    context 'when no match exists' do
      it 'returns nil' do
        expect(email.constituent_id_for_email('email@mailbox.com')).to eq nil
      end
    end
  end

  describe '#constituent_names' do
    let(:constituents) { create_list :constituent, 3 }

    it 'returns a string of related constituent names' do
      email.matched_constituents = constituents.pluck(:id)

      expect(email.constituent_names).to eq constituents.pluck(:name).join(', ')
    end
  end

  private

  describe '#deny_internal_messages' do
    let(:email) { build :email }

    it 'fires on validation' do
      expect(email).to receive(:deny_internal_messages)

      email.valid?
    end

    context 'when from or to are blank' do
      let(:no_from) { build :email, from: [] }
      let(:no_to) { build :email, to: [] }

      it 'returns false' do
        expect(no_from.__send__(:deny_internal_messages)).to eq false
        expect(no_to.__send__(:deny_internal_messages)).to eq false
      end
    end

    context 'when all emails match INTERNAL_DOMAINS' do
      let(:internal) { build :email, from: ['internal@20liters.org'], to: ['staff@twentyliters.com', 'copier@20litres.org'] }

      it 'returns false and adds an error' do
        expect(internal.__send__(:deny_internal_messages)).to eq false
        expect(internal.errors[:from]).to include 'Internal Emails only!'
      end
    end

    context 'when at least one email does not match INTERNAL_DOMAINS' do
      let(:external_to) { build :email, from: ['internal@20liters.org'], to: ['staff@twentyliters.com', 'copier@20litres.org', 'person@external.org'] }
      let(:external_from) { build :email, from: ['person@external.org'], to: ['staff@twentyliters.com', 'copier@20litres.org'] }

      it 'returns true' do
        expect(external_to.__send__(:deny_internal_messages)).to eq true
        expect(external_from.__send__(:deny_internal_messages)).to eq true
      end
    end
  end

  describe '#deny_unmatched_messages' do
    let(:email) { build :email }

    it 'fires on validation' do
      expect(email).to receive(:deny_unmatched_messages)

      email.valid?
    end

    context 'when a matching Constituent exists' do
      it 'returns true' do
        expect(email.__send__(:deny_unmatched_messages)).to eq true
      end
    end

    context 'when no matching Constituent exists' do
      before do
        email.matched_constituents = []
        allow(email).to receive(:match_to_constituents).and_return true
      end

      it 'returns false and adds an error' do
        expect(email.__send__(:deny_unmatched_messages)).to eq false

        expect(email.errors[:from]).to include 'No matches in database!'
      end
    end
  end

  describe '#match_to_constituents' do
    let(:email) { build :email, matched_constituents: [] }

    it 'populates #matched_constituents array' do
      create :constituent, primary_email: email.to[0]
      # debugger

      expect { email.__send__(:match_to_constituents) }
        .to change { email.matched_constituents }
        .from([])
        .to([email.constituent_id_for_email(email.to[0]).to_s])
    end

    context 'when Constituent sent the email' do
      let(:email_to) { build :email_to }

      it 'sets #direction to "sent"' do
        expect { email_to.__send__(:match_to_constituents) }
          .to change { email_to.direction }
          .from(nil)
          .to('sent')
      end
    end

    context 'when Constituent received the email' do
      it 'sets #direction to "received"' do
        expect { email.__send__(:match_to_constituents) }
          .to change { email.direction }
          .from(nil)
          .to('received')
      end
    end
  end

  describe '#as_bloomerang_interaction' do
    fit 'returns a JSON hash' do
      return_hash = email.__send__(:as_bloomerang_interaction, email.matched_constituents[0])

      expect(return_hash.keys - %w[AccountId Date Channel Purpose Subject Note IsInbound]).to eq []
    end
  end
end
