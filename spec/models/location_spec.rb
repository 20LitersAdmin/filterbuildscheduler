# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Location, type: :model do
  let(:location) { create :location }

  describe 'must be valid' do
    let(:no_name) { build :location, name: nil }
    let(:no_addr) { build :location, address1: nil }
    let(:no_city) { build :location, city: nil }
    let(:no_state) { build :location, state: nil }
    let(:no_zip) { build :location, zip: nil }

    it 'in order to save' do
      expect(location.save).to eq true
      expect { no_name.save!(validate: false) }
        .to raise_error ActiveRecord::NotNullViolation
      expect(no_addr.save).to be_falsey
      expect(no_city.save).to be_falsey
      expect(no_state.save).to be_falsey
      expect(no_zip.save).to be_falsey
    end
  end

  describe 'can be destroyed' do
    it 'when associated with a user' do
      leader = create(:leader, primary_location_id: location.id)

      expect { location.destroy }
        .to change { Location.all.size }
        .by(-1)

      expect(leader.reload.technologies).not_to include location
    end

    it 'when associated with an event' do
      event = create(:event, location:)

      expect { location.destroy }
        .to change { Location.all.size }
        .by(-1)

      expect(event.reload.location).to eq nil
    end
  end

  describe '#one_liner' do
    it 'concatentates the city, state and zip' do
      expect(location.one_liner).to include location.city
      expect(location.one_liner).to include location.state
      expect(location.one_liner).to include location.zip
    end
  end

  describe '#address' do
    context 'when address2 is present' do
      it 'formats address1 and address2' do
        expect(location.address).to include ', '
        expect(location.address).to include location.address2
      end
    end

    context 'when address2 is not present' do
      it 'returns address1' do
        location.address2 = nil

        expect(location.address).not_to include ', '
        expect(location.address).to eq location.address1
      end
    end
  end

  describe '#address_block' do
    it 'calls html_safe' do
      allow_any_instance_of(String).to receive(:html_safe)

      expect_any_instance_of(String).to receive(:html_safe)

      location.address_block
    end

    it 'formats a complete address' do
      expect(location.address_block).to include location.address1
      expect(location.address_block).to include location.address2
      expect(location.address_block).to include location.city
      expect(location.address_block).to include location.state
      expect(location.address_block).to include location.zip
    end
  end

  describe '#addr_one_liner' do
    it 'formats an address' do
      expect(location.addr_one_liner).to include location.address1
      expect(location.addr_one_liner).to include location.address2
      expect(location.addr_one_liner).to include location.city
      expect(location.addr_one_liner).to include location.state
      expect(location.addr_one_liner).to include location.zip
    end
  end

  private

  describe '#name_underscore' do
    it 'returns a string with no spaces or capital letters' do
      # regex that matches spaces or capital letters
      regex = /( |[A-Z])/
      location.name = '20 Liters'

      expect(location.name =~ regex).not_to eq nil
      expect(location.__send__(:name_underscore) =~ regex).to eq nil
    end
  end

  describe '#process_image' do
    before :each do
      # https://edgeapi.rubyonrails.org/classes/ActiveStorage/Attached/One.html#method-i-attach:
      # If the record is persisted and unchanged, the attachment is saved to the database immediately. Otherwise, it'll be saved to the DB when the record is next saved.
      @file = File.open('./app/assets/images/logo-horizontal-417-208.png')
      location.name = 'Dirty Record'
      location.image.attach(io: @file, filename: 'test_img.png', content_type: 'image/png')
    end

    it 'fires on before_save' do
      expect(location).to receive(:process_image)

      location.save
    end

    it 'changes the filename' do
      expect(location.image.filename.to_s).to eq 'test_img.png'

      location.save

      expect(location.reload.image.filename.to_s).to eq "dirty_record_#{Date.today.iso8601}.png"
    end

    it 'saves the image' do
      expect(location.image.attachment.id).to eq nil

      location.save

      expect(location.reload.image.attachment.id).to be > 0
    end
  end
end
