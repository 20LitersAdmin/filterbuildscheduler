# frozen_string_literal: true

require 'rails_helper'

require 'concerns/itemable_spec'

RSpec.describe Part, type: :model do
  it_behaves_like Itemable

  let(:part) { create :part }

  describe 'must be valid' do
    let(:no_name) { build :part, name: nil }
    let(:no_price) { build :part, price_cents: nil }
    let(:no_quantity) { build :part_from_material, quantity_from_material: nil }

    let(:negative_price) { build :part, price_cents: -299 }

    it 'in order to save' do
      expect(part.save).to eq true

      expect { no_name.save!(validate: false) }
        .to raise_error ActiveRecord::NotNullViolation
      expect { no_price.save!(validate: false) }
        .to raise_error ActiveRecord::NotNullViolation

      expect(no_quantity.valid?).to eq false
      expect(no_quantity.errors.messages[:quantity_from_material]).to include "can't be blank"
    end

    it 'prices can\'t be negative' do
      expect(negative_price.save).to be_falsey
    end
  end

  describe 'Part#search_name_and_uid(string)' do
    context 'when string is blank' do
      it 'returns Part.none' do
        expect(Part.search_name_and_uid('')).to eq Part.none
      end
    end

    context 'when string is not a String' do
      it 'returns Part.none' do
        expect(Part.search_name_and_uid(256)).to eq Part.none
        expect(Part.search_name_and_uid(%w[ary with items])).to eq Part.none
        expect(Part.search_name_and_uid(true)).to eq Part.none
      end
    end

    context 'when string is a String' do
      let(:blue) { create :part, name: 'blue part' }
      let(:red) { create :part, name: 'thing that is red' }
      let(:green) { create :part, name: 'green object' }
      let(:uid) { create :part }

      it 'performs an SQL ILIKE any match against :uid and :name' do
        blue
        red
        green
        string = "blue red #{uid.uid}"

        expect(Part.search_name_and_uid(string)).to include blue
        expect(Part.search_name_and_uid(string)).to include red
        expect(Part.search_name_and_uid(string)).not_to include green
        expect(Part.search_name_and_uid(string)).to include uid
      end
    end
  end

  describe '#on_order?' do
    # early returns:
    context 'when last_ordered_at is not present' do
      it 'returns false' do
        expect(part.last_ordered_at).to eq nil
        expect(part.on_order?).to eq false
      end
    end

    context 'when last_received_at is nil' do
      it 'returns true' do
        part.last_ordered_at = Time.now - 2.days
        part.last_ordered_quantity = 200
        expect(part.last_ordered_at.present?).to eq true
        expect(part.last_received_at.nil?).to eq true
        expect(part.on_order?).to eq true
      end
    end

    context 'when partial_received? is true' do
      it 'returns true' do
        part.last_ordered_at = Time.now - 2.days
        part.last_ordered_quantity = 200
        part.last_received_at = Time.now - 1.day
        part.last_received_quantity = 50
        expect(part.last_ordered_at.present?).to eq true
        expect(part.last_received_at.nil?).to eq false
        expect(part.partial_received?).to eq true

        expect(part.on_order?).to eq true
      end
    end

    context 'when last_ordered_at is present, last_received_at is not nil, and partial_received is false' do
      before :each do
        part.last_ordered_at = Time.now - 2.days
        part.last_ordered_quantity = 20
        part.last_received_at = Time.now - 1.year
      end

      context 'when last_ordered_at > last_received_at' do
        it 'returns true' do
          expect(part.last_ordered_at > part.last_received_at).to eq true
          expect(part.on_order?).to eq true
        end
      end

      context 'when last_ordered_at <= last_received_at' do
        it 'returns false' do
          part.last_ordered_at = Time.now - 2.years
          expect(part.last_ordered_at <= part.last_received_at).to eq true
          expect(part.on_order?).to eq false
        end
      end
    end
  end

  describe '#reorder_total_cost' do
    it 'returns a Money object' do
      expect(part.reorder_total_cost.class).to eq Money
    end
    it 'multiplies min_order * price' do
      part.min_order = 20
      part.price_cents = 500

      expect(part.reorder_total_cost).to eq Money.new(100_00)
    end
  end

  describe '#super_assemblies' do
    let(:asbly1) { create :assembly, item: part }
    let(:asbly2) { create :assembly, item: part }
    let(:asbly3) { create :assembly }

    it 'is an alias of assemblies' do
      expect(part.super_assemblies).to include asbly1
      expect(part.super_assemblies).to include asbly2
      expect(part.super_assemblies).not_to include asbly3
    end
  end

  describe '#supplier_and_sku' do
    context 'when part.made_from_material?' do
      let(:part_from_material) { build :part_from_material, made_from_material: true }

      it 'returns an empty string' do
        expect(part_from_material.supplier_and_sku).to eq ''
      end
    end
    context 'when order_url.nil?' do
      it 'returns supplier.name' do
        expect(part.supplier_and_sku).to eq part.supplier.name
      end
    end

    context 'when order_url.present?' do
      before :each do
        part.order_url = 'https://supplier-website.com'
        part.sku = 'ABC123'
      end

      context 'when sku.nil?' do
        before :each do
          part.sku = nil
        end

        it 'uses the word link instead' do
          expect(part.supplier_and_sku).to include 'link'
        end
      end

      it 'returns an HTML-safe string' do
        # ActionController::Base.helpers.link_to also calls :html_safe
        helpers = instance_double(ActionView::Base)
        double_class = class_double(ActionController::Base).as_stubbed_const
        allow(double_class).to receive(:helpers).and_return(helpers)
        allow(helpers).to receive(:link_to)

        expect_any_instance_of(String).to receive(:html_safe)

        part.supplier_and_sku
      end

      it 'returns supplier and a link with the sku' do
        expect(part.supplier_and_sku).to include part.supplier.name
        expect(part.supplier_and_sku).to include ' - SKU: '
        expect(part.supplier_and_sku).to include '<a target="_blank" rel="tooltip"'
        expect(part.supplier_and_sku).to include part.sku
      end
    end
  end

  describe '#sub_assemblies' do
    it 'returns Assembly.none' do
      expect(part.sub_assemblies).to eq Assembly.none
    end
  end

  private

  describe '#process_image' do
    before :each do
      # https://edgeapi.rubyonrails.org/classes/ActiveStorage/Attached/One.html#method-i-attach:
      # If the record is persisted and unchanged, the attachment is saved to the database immediately. Otherwise, it'll be saved to the DB when the record is next saved.
      @file = File.open('./app/assets/images/logo-horizontal-417-208.png')
      part.name = 'Dirty Record'
      part.image.attach(io: @file, filename: 'test_img.png', content_type: 'image/png')
    end

    it 'fires on before_save' do
      expect(part).to receive(:process_image)

      part.save
    end

    it 'changes the filename' do
      expect(part.image.filename.to_s).to eq 'test_img.png'

      part.save

      expect(part.reload.image.filename.to_s).to eq "#{part.uid}_#{Date.today.iso8601}.png"
    end

    it 'saves the image' do
      expect(part.image.attachment.id).to eq nil

      part.save

      expect(part.reload.image.attachment.id).to be > 0
    end
  end

  describe '#run_jobs_related_to_quantity_from_material' do
    context 'after save when quantity_from_material || made_from_material has' do
      it 'not changed, it does not fire' do
        expect(part).not_to receive(:run_jobs_related_to_quantity_from_material)
        part.save
      end
      it 'changed, it fires' do
        expect(part).to receive(:run_jobs_related_to_quantity_from_material)
        part.quantity_from_material = 3.5
        part.save
      end
    end

    it 'enqueues ProduceableJob' do
      # Itemable#run_update_jobs also enqueues this job
      allow(part).to receive(:run_update_jobs).and_return(true)

      expect { part.__send__(:run_jobs_related_to_quantity_from_material) }
        .to have_enqueued_job(ProduceableJob)
    end

    it 'enqueues GoalRemainderCalculationJob' do
      # Itemable#run_update_jobs also enqueues this job
      allow(part).to receive(:run_update_jobs).and_return(true)

      expect { part.__send__(:run_jobs_related_to_quantity_from_material) }
        .to have_enqueued_job(GoalRemainderCalculationJob)
    end
  end

  describe '#set_made_from_material' do
    it 'fires before validation' do
      expect(part).to receive(:set_made_from_material)
      part.valid?
    end

    context 'when a material is present' do
      let(:material) { create :material }

      it 'sets made_from_material to true' do
        expect(part.made_from_material).to eq false
        part.material = material
        part.valid?
        expect(part.made_from_material).to eq true
      end
    end

    context 'when a material is not present' do
      it 'sets made_from_material to false' do
        part.made_from_material = true
        expect(part.made_from_material).to eq true
        part.material = nil
        part.valid?
        expect(part.made_from_material).to eq false
      end
    end

    it 'sets quantity_from_material if its zero' do
      part.quantity_from_material = 0
      part.valid?
      expect(part.quantity_from_material).to eq 1.0
    end
  end
end
