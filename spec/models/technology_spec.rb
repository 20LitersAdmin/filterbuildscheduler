# frozen_string_literal: true

require 'rails_helper'
require 'concerns/itemable_spec'

RSpec.describe Technology, type: :model do
  it_behaves_like Itemable

  let(:technology) { create :technology }

  describe 'must be valid' do
    let(:no_name) { build :technology, name: nil, short_name: nil }
    let(:no_people) { build :technology, people: nil }
    let(:no_lifespan) { build :technology, lifespan_in_years: nil }

    it 'in order to save' do
      expect(technology.save).to eq true

      expect { no_name.save!(validate: false) }
        .to raise_error ActiveRecord::NotNullViolation
      expect { no_people.save!(validate: false) }
        .to raise_error ActiveRecord::NotNullViolation
      expect { no_lifespan.save!(validate: false) }
        .to raise_error ActiveRecord::NotNullViolation
    end
  end

  describe 'can be destroyed' do
    it 'when associated with a user' do
      leader = create(:leader)
      leader.technologies << technology

      expect { technology.destroy }
        .to change { Technology.all.size }
        .by(-1)

      expect(leader.reload.technologies).not_to include technology
    end

    it 'when associated with an event' do
      event = create(:event, technology: technology)

      expect { technology.destroy }
        .to change { Technology.all.size }
        .by(-1)

      expect(event.reload.technology).to eq nil
    end
  end

  describe '#all_components' do
    before do
      3.times do
        comp = create :component
        technology.quantities[comp.uid] = 1
      end
      technology.save

      create_list :component, 3
    end
    it 'returns a collection of Components' do
      expect(technology.all_components.pluck(:uid).sort).to eq technology.quantities.keys.sort
    end
  end

  describe '#all_parts' do
    before do
      3.times do
        part = create :part
        technology.quantities[part.uid] = 1
      end
      technology.save

      create_list :part, 3
    end
    it 'returns a collection of Parts' do
      expect(technology.all_parts.pluck(:uid).sort).to eq technology.quantities.keys.sort
    end
  end

  describe '#materials' do
    before do
      3.times do
        material = create :material
        technology.quantities[material.uid] = 1
      end
      technology.save

      create_list :material, 3
    end
    it 'returns a collection of Materials' do
      expect(technology.materials.pluck(:uid).sort).to eq technology.quantities.keys.sort
    end
  end

  describe '#owner_acronym' do
    let(:owner1) { 'The Winchester Group' }
    let(:owner2) { 'soho metals, inc' }
    let(:owner3) { '20 Liters' }

    it 'returns the first letter of each word charater in the string and any digits' do
      technology.owner = owner1
      expect(technology.owner_acronym).to eq 'TWG'

      technology.owner = owner2
      expect(technology.owner_acronym).to eq 'smi'

      technology.owner = owner3
      expect(technology.owner_acronym).to eq '20L'
    end
  end

  describe '#results_worthy?' do
    let(:not_worthy) { build :technology, people: 0, lifespan_in_years: 0, liters_per_day: 0 }

    context 'when certain fields are positive' do
      it 'returns true' do
        expect(technology.results_worthy?).to eq true
      end
    end

    context 'when certain fields are not positive' do
      it 'returns false' do
        expect(not_worthy.results_worthy?).to eq false

        not_worthy.people = 1
        expect(not_worthy.results_worthy?).to eq false

        not_worthy.lifespan_in_years = 1
        expect(not_worthy.results_worthy?).to eq false

        not_worthy.liters_per_day = 1
        expect(not_worthy.results_worthy?).to eq true
      end
    end
  end

  describe '#short_name_w_owner' do
    it 'returns a string with the short_name and owner_acronym' do
      expect(technology.short_name_w_owner).to include technology.short_name
      expect(technology.short_name_w_owner).to include technology.owner_acronym
    end
  end

  private

  describe '#name_underscore' do
    it 'returns the owner name suitable for use as a filename' do
      technology.name = '20;- LiTerS,  yeah!!!'

      expect(technology.__send__(:name_underscore)).to eq '20_liters_yeah'
    end
  end

  describe '#process_image' do
    before :each do
      # https://edgeapi.rubyonrails.org/classes/ActiveStorage/Attached/One.html#method-i-attach:
      # If the record is persisted and unchanged, the attachment is saved to the database immediately. Otherwise, it'll be saved to the DB when the record is next saved.
      @file = File.open('./app/assets/images/logo-horizontal-417-208.png')
      technology.name = 'Dirty Record'
      technology.image.attach(io: @file, filename: 'test_img.png', content_type: 'image/png')
    end

    it 'fires on before_save' do
      expect(technology).to receive(:process_images)

      technology.save
    end

    it 'changes the filename' do
      expect(technology.image.filename.to_s).to eq 'test_img.png'

      technology.save

      expect(technology.reload.image.filename.to_s).to eq "dirty_record_image_#{Date.today.iso8601}.png"
    end

    it 'saves the image' do
      expect(technology.image.attachment.id).to eq nil

      technology.save

      expect(technology.reload.image.attachment.id).to be > 0
    end
  end
end
