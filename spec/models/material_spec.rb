# frozen_string_literal: true

require 'rails_helper'
require 'concerns/itemable_spec'

RSpec.describe Material, type: :model do
  it_behaves_like Itemable

  let(:material) { create :material }

  describe 'must be valid' do
    let(:no_name) { build :material, name: nil }
    let(:no_price) { build :material, price_cents: nil }

    let(:negative_price) { build :material, price_cents: -300 }

    it 'in order to save' do
      expect(material.save).to eq true
      expect { no_name.save!(validate: false) }
        .to raise_error ActiveRecord::NotNullViolation
      expect { no_price.save!(validate: false) }
        .to raise_error ActiveRecord::NotNullViolation
    end

    it 'prices must be positive' do
      expect(negative_price.save).to be_falsey
    end
  end

  describe '#on_order?' do
    # early returns:
    context 'when last_ordered_at is not present' do
      it 'returns false' do
        expect(material.last_ordered_at).to eq nil
        expect(material.on_order?).to eq false
      end
    end

    context 'when last_received_at is nil' do
      it 'returns true' do
        material.last_ordered_at = Time.now - 2.days
        material.last_ordered_quantity = 200
        expect(material.last_ordered_at.present?).to eq true
        expect(material.last_received_at.nil?).to eq true

        expect(material.on_order?).to eq true
      end
    end

    context 'when partial_received? is true' do
      it 'returns true' do
        material.last_ordered_at = Time.now - 2.days
        material.last_ordered_quantity = 200
        material.last_received_at = Time.now - 1.day
        material.last_received_quantity = 50
        expect(material.last_ordered_at.present?).to eq true
        expect(material.last_received_at.nil?).to eq false
        expect(material.partial_received?).to eq true

        expect(material.on_order?).to eq true
      end
    end

    context 'when last_ordered_at is present, last_received_at is not nil, and partial_received is false' do
      before :each do
        material.last_ordered_at = Time.now - 2.days
        material.last_ordered_quantity = 20
        material.last_received_at = Time.now - 1.year
      end

      context 'when last_ordered_at > last_received_at' do
        it 'returns true' do
          expect(material.last_ordered_at > material.last_received_at).to eq true
          expect(material.on_order?).to eq true
        end
      end

      context 'when last_ordered_at <= last_received_at' do
        it 'returns false' do
          material.last_ordered_at = Time.now - 2.years
          expect(material.last_ordered_at <= material.last_received_at).to eq true

          expect(material.on_order?).to eq false
        end
      end
    end
  end

  describe '#owners' do
    context 'when not associated to a technology' do
      it 'returns [N/A]' do
        expect(material.owners).to eq ['N/A']
      end
    end

    context 'when one or more technology is associated' do
      let(:technology) { create :technology, quantities: { material.uid => 1 } }

      it 'returns an array of all owners via all_technologies' do
        technology

        expect(material.owners.class).to eq Array

        expect(material.owners).to include technology.owner_acronym
      end
    end
  end

  describe '#reorder?' do
    context 'when available_count < minimum_on_hand' do
      it 'returns true' do
        material.available_count = 1
        material.minimum_on_hand = 2

        expect(material.reorder?).to eq true
      end
    end

    context 'when available_count >= minimum_on_hand' do
      it 'returns false' do
        material.minimum_on_hand = 10
        material.available_count = 10

        expect(material.reorder?).to eq false

        material.available_count = 12
        expect(material.reorder?).to eq false
      end
    end
  end

  describe '#reorder_total_cost' do
    it 'returns a Money object' do
      expect(material.reorder_total_cost.class).to eq Money
    end
    it 'multiplies min_order * price' do
      material.min_order = 20
      material.price_cents = 500

      expect(material.reorder_total_cost).to eq Money.new(100_00)
    end
  end

  describe '#supplier_and_sku' do
    context 'when order_url.nil?' do
      it 'returns supplier.name' do
        expect(material.supplier_and_sku).to eq material.supplier.name
      end
    end

    context 'when order_url.present?' do
      before :each do
        material.order_url = 'https://supplier-website.com'
        material.sku = 'ABC123'
      end

      context 'when sku.nil?' do
        before :each do
          material.sku = nil
        end

        it 'uses the word link instead' do
          expect(material.supplier_and_sku).to include 'link'
        end
      end

      it 'returns an HTML-safe string' do
        # ActionController::Base.helpers.link_to also calls :html_safe
        helpers = instance_double(ActionView::Base)
        double_class = class_double(ActionController::Base).as_stubbed_const
        allow(double_class).to receive(:helpers).and_return(helpers)
        allow(helpers).to receive(:link_to)

        expect_any_instance_of(String).to receive(:html_safe)

        material.supplier_and_sku
      end

      it 'returns supplier and a link with the sku' do
        expect(material.supplier_and_sku).to include material.supplier.name
        expect(material.supplier_and_sku).to include ' - SKU: '
        expect(material.supplier_and_sku).to include '<a target="_blank" rel="tooltip"'
        expect(material.supplier_and_sku).to include material.sku
      end
    end
  end

  private

  describe '#process_image' do
    before :each do
      # https://edgeapi.rubyonrails.org/classes/ActiveStorage/Attached/One.html#method-i-attach:
      # If the record is persisted and unchanged, the attachment is saved to the database immediately. Otherwise, it'll be saved to the DB when the record is next saved.
      @file = File.open('./app/assets/images/logo-horizontal-417-208.png')
      material.name = 'Dirty Record'
      material.image.attach(io: @file, filename: 'test_img.png', content_type: 'image/png')
    end

    it 'fires on before_save' do
      expect(material).to receive(:process_image)

      material.save
    end

    it 'changes the filename' do
      expect(material.image.filename.to_s).to eq 'test_img.png'

      material.save

      expect(material.reload.image.filename.to_s).to eq "#{material.uid}_#{Date.today.iso8601}.png"
    end

    it 'saves the image' do
      expect(material.image.attachment.id).to eq nil

      material.save

      expect(material.reload.image.attachment.id).to be > 0
    end
  end
end
