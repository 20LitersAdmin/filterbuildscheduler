# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Count, type: :model do
  let(:count) { create :count_part }

  describe 'must be valid' do
    let(:no_inv)    { build :count_part, inventory_id: nil }
    let(:no_loose)  { build :count_part, loose_count: nil }
    let(:no_box)    { build :count_part, unopened_boxes_count: nil }

    it 'in order to save' do
      expect { no_inv.save!(validate: false) }
        .to raise_error ActiveRecord::NotNullViolation
      expect { no_loose.save!(validate: false) }
        .to raise_error ActiveRecord::NotNullViolation
      expect { no_box.save!(validate: false) }
        .to raise_error ActiveRecord::NotNullViolation
    end
  end

  describe '#available' do
    let(:part) { create :part, quantity_per_box: 10 }
    let(:count2) { create :count_part, item: part, unopened_boxes_count: 5, loose_count: 10 }

    it 'calculates the number of items available' do
      expect(count2.available).to eq(60)
    end
  end

  describe '#box_count' do
    let(:part) { create :part, quantity_per_box: 10 }
    let(:count2) { create :count_part, item: part, unopened_boxes_count: 5, loose_count: 10 }

    it 'calculates the individual items based upon the quantity_per_box of the associated item' do
      expect(count2.box_count).to eq(50)
    end
  end

  describe '#history_hash_for_inventory' do
    it 'returns a hash' do
      expect(count.history_hash_for_inventory.class).to eq Hash
    end

    it 'includes item_name' do
      expect(count.history_hash_for_inventory[:item_name]).to eq count.item.name
    end
  end

  describe '#history_hash_for_item' do
    it 'returns a hash' do
      expect(count.history_hash_for_item.class).to eq Hash
    end

    it 'includes inv_type' do
      expect(count.history_hash_for_item[:inv_type]).to eq count.inventory.type
    end
  end

  describe '#link_text' do
    let(:count_submitted) { create :count_submitted }
    let(:count_partial_box) { create :count, partial_box: true }
    let(:count_partial_loose) { create :count, partial_loose: true }

    context 'when count has a user_id' do
      it 'returns Edit' do
        expect(count_submitted.link_text).to eq 'Edit'
      end
    end

    context 'when count.partial_box is true' do
      it 'returns Loose Count' do
        expect(count_partial_box.link_text).to eq 'Loose Count'
      end
    end

    context 'when count.partial_loose is true' do
      it 'returns Box Count' do
        expect(count_partial_loose.link_text).to eq 'Box Count'
      end
    end

    context 'when count is unsubmitted' do
      context 'and inventory is receiving' do
        let(:inventory_rec) { create :inventory_rec }
        let(:count2) { create :count, inventory: inventory_rec }

        it 'returns "Receive"' do
          expect(count2.link_text).to eq 'Receive'
        end
      end

      context 'and inventory is shipping' do
        let(:inventory_ship) { create :inventory_ship }
        let(:count2) { create :count, inventory: inventory_ship }

        it 'returns "Ship"' do
          expect(count2.link_text).to eq 'Ship'
        end
      end

      context 'and inventory is manual' do
        let(:inventory_man) { create :inventory_man }
        let(:count2) { create :count, inventory: inventory_man }

        it 'returns "Count"' do
          expect(count2.link_text).to eq 'Count'
        end
      end

      context 'and inventory is event' do
        let(:inventory_event) { create :inventory_event }
        let(:count2) { create :count, inventory: inventory_event }

        it 'returns "Adjust"' do
          expect(count2.link_text).to eq 'Adjust'
        end
      end

      context 'and inventory type is unknown' do
        let(:inventory) { create :inventory, manual: false }
        let(:count2) { create :count, inventory: inventory }

        it 'returns "Adjust"' do
          expect(count2.link_text).to eq 'Adjust'
        end
      end
    end
  end

  describe '#link_class' do
    context 'when count has a user_id' do
      let(:count_submitted) { create :count_submitted }

      it 'returns blue' do
        expect(count_submitted.link_class).to eq 'blue'
      end
    end

    context 'when count.partial_box is true' do
      let(:count_partial_box) { create :count, partial_box: true }

      it 'returns "empty"' do
        expect(count_partial_box.link_class).to eq 'empty'
      end
    end

    context 'when count.partial_loose is true' do
      let(:count_partial_loose) { create :count, partial_loose: true }

      it 'returns "empty"' do
        expect(count_partial_loose.link_class).to eq 'empty'
      end
    end

    context 'when count has not been submitted' do
      it 'returns "yellow"' do
        expect(count.link_class).to eq 'yellow'
      end
    end
  end

  describe '#sort_by_status' do
    context 'when count has a user_id' do
      let(:count_submitted) { create :count_submitted }

      it 'returns 2' do
        expect(count_submitted.sort_by_status).to eq 2
      end
    end

    context 'when count.partial_box is true' do
      let(:count_partial_box) { create :count, partial_box: true }

      it 'returns 1' do
        expect(count_partial_box.sort_by_status).to eq 1
      end
    end

    context 'when count.partial_loose is true' do
      let(:count_partial_loose) { create :count, partial_loose: true }

      it 'returns 1' do
        expect(count_partial_loose.sort_by_status).to eq 1
      end
    end

    context 'when count has not been submitted' do
      it 'returns 0' do
        expect(count.sort_by_status).to eq 0
      end
    end
  end
end
