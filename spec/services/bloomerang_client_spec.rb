# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BloomerangClient do
  let(:client) { BloomerangClient.new(:buildscheduler) }

  it 'stores accessible variables' do
    expect(client.app.class).to eq Symbol
    expect(client.bloomerang).to eq Bloomerang
    expect(client.response.class).to eq Hash
    expect(client.total_records.class).to eq Integer
    expect(client.created_record_ids.class).to eq Array
    expect(client.last_modified.class).to eq String
  end

  describe '#configure_bloomerang' do
    it 'sets the configuration for Bloomerang' do
      client

      expect(Bloomerang).to receive(:configure)

      client.__send__(:configure_bloomerang)
    end
  end

  describe '#import_constituents!' do
    let(:constituent_fetch) { JSON.parse(File.read("#{Rails.root}/spec/fixtures/files/bloomerang_constituent_fetch.json")) }

    before do
      allow(Bloomerang::Constituent).to receive(:fetch).and_return(constituent_fetch)
    end

    it 'creates Constituent records in the database' do
      expect { client.import_constituents! }
        .to change { Constituent.count }
        .from(0)
        .to(50)
    end
  end

  describe '#import_emails!' do
    let(:email_fetch) { JSON.parse(File.read("#{Rails.root}/spec/fixtures/files/bloomerang_email_fetch.json")) }

    before do
      allow(Bloomerang::Email).to receive(:fetch).and_return(email_fetch)
    end

    it 'creates ConstituentEmail records in the database' do
      expect { client.import_emails! }
        .to change { ConstituentEmail.count }
        .from(0)
        .to(50)
    end
  end

  describe '#import_phones!' do
    let(:phone_fetch) { JSON.parse(File.read("#{Rails.root}/spec/fixtures/files/bloomerang_phone_fetch.json")) }

    before do
      allow(Bloomerang::Phone).to receive(:fetch).and_return(phone_fetch)
    end

    it 'creates ConstituentPhone records in the database' do
      expect { client.import_phones! }
        .to change { ConstituentPhone.count }
        .from(0)
        .to(50)
    end
  end

  describe '#create_from_causevox' do
    let(:charge) { JSON.parse(File.read("#{Rails.root}/spec/fixtures/files/charge_succeeded_spec.json")) }
    let(:stripe_charge) { StripeCharge.new(charge) }

    before do
      allow(Bloomerang::Appeal).to receive(:fetch).and_return({ Results: [] }.as_json)
      allow(Bloomerang::Appeal).to receive(:create).and_return({ Id: 0 }.as_json)
      allow(Bloomerang::Constituent).to receive(:create).and_return({ Id: 0 }.as_json)
    end

    it 'sends data to Bloomerang::Constituent.create' do
      expect(Bloomerang::Constituent).to receive(:create).with(stripe_charge.as_bloomerang_constituent)

      client.create_from_causevox(stripe_charge)
    end

    it 'sends data to Bloomerang::Transaction.create' do
      expect(Bloomerang::Transaction).to receive(:create).with(stripe_charge.as_bloomerang_transaction(0))

      client.create_from_causevox(stripe_charge)
    end
  end
end
