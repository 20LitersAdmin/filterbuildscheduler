# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CountTransferJob, type: :job do
  let(:job) { CountTransferJob.new }

  it 'queues as count_transfer' do
    expect(job.queue_name).to eq 'count_transfer'
  end

  describe '#perform' do
    context 'when inventory is nil, empty or blank' do
      it 'returns nil' do
        expect(job.perform(nil)).to eq nil
      end
    end

    context 'when inventory is manual' do
      before do
        @inventory = create :inventory

        create_list :count_submitted, 9, inventory: @inventory
        create_list :count, 2, inventory: @inventory
      end

      it 'calls transfer_manual_count for each submitted count' do
        expect(job).to receive(:transfer_manual_count).exactly(9).times

        job.perform(@inventory)
      end
    end

    context 'when inventory is event_based' do
      before do
        @inventory = create :inventory_event

        create_list :count_submitted, 9, inventory: @inventory
        create_list :count, 2, inventory: @inventory
      end

      it 'calls transfer_auto_count for every count' do
        expect(job).to receive(:transfer_auto_count).exactly(11).times

        job.perform(@inventory)
      end
    end

    context 'when inventory is shipping' do
      before do
        @inventory = create :inventory_ship

        create_list :count_submitted, 5, inventory: @inventory
        create_list :count, 3, inventory: @inventory
      end

      it 'calls transfer_auto_count for each submitted count' do
        expect(job).to receive(:transfer_auto_count).exactly(5).times

        job.perform(@inventory)
      end
    end

    context 'when inventory is receiving' do
      before do
        @inventory = create :inventory_rec

        create_list :count_submitted, 7, inventory: @inventory
        create_list :count, 3, inventory: @inventory
      end

      it 'calls transfer_auto_count for each submitted count' do
        expect(job).to receive(:transfer_auto_count).exactly(7).times

        job.perform(@inventory)
      end
    end

    context 'after transferring counts' do
      before do
        @inventory = create :inventory

        create_list :count_submitted, 9, inventory: @inventory
        create_list :count, 2, inventory: @inventory
      end

      it 'saves the history to the inventory' do
        expect { job.perform(@inventory) }
          .to change { @inventory.history.size }
          .from(0).to(9)
      end

      it 'calls destroy_all on the associated counts' do
        expect(@inventory.counts).to receive(:destroy_all)

        job.perform(@inventory)
      end
    end
  end

  describe '#transfer_auto_count' do
    let(:inventory) { create :inventory_rec }
    let(:part) { create :part, loose_count: 5, box_count: 2, available_count: 25, quantity_per_box: 10 }
    let(:count) { create :count_submitted, inventory: inventory, loose_count: 8, unopened_boxes_count: 1, item: part }

    it 'combines Count values with Item values' do
      job.inventory = inventory

      expect(part.loose_count).to eq 5
      expect(part.box_count).to eq 2
      expect(part.available_count).to eq 25

      job.transfer_auto_count(count)

      expect(part.loose_count).to eq 13
      expect(part.box_count).to eq 3
      expect(part.available_count).to eq 43
    end

    it 'saves the item' do
      job.inventory = inventory

      expect(part).to receive(:save).once

      job.transfer_auto_count(count)
    end

    it 'adds the item UID to the inventory.history' do
      job.inventory = inventory

      expect(inventory.history[part.uid]).to eq nil

      job.transfer_auto_count(count)

      expect(inventory.history[part.uid]).to eq count.history_hash_for_inventory
    end

    context 'when inventory is receiving' do
      it 'updates the item.last_received_* values' do
        job.inventory = inventory
        job.receiving = true

        expect(part.last_received_at).to eq nil
        expect(part.last_received_quantity).to eq nil

        job.transfer_auto_count(count)

        part.reload

        expect(part.last_received_at).not_to eq nil
        expect(part.last_received_quantity).to eq 18
      end
    end
  end

  describe '#transfer_manual_count' do
    let(:inventory) { create :inventory }
    let(:part) { create :part, loose_count: 5, box_count: 2, available_count: 25, quantity_per_box: 10 }
    let(:count) { create :count_submitted, inventory: inventory, loose_count: 8, unopened_boxes_count: 1, item: part }

    it 'combines Count values with Item values' do
      job.inventory = inventory

      expect(part.loose_count).to eq 5
      expect(part.box_count).to eq 2
      expect(part.available_count).to eq 25

      job.transfer_manual_count(count)

      expect(part.loose_count).to eq 8
      expect(part.box_count).to eq 1
      expect(part.available_count).to eq 18
    end

    it 'saves the item' do
      job.inventory = inventory

      expect(part).to receive(:save).once

      job.transfer_manual_count(count)
    end

    it 'adds the item UID to the inventory.history' do
      job.inventory = inventory

      expect(inventory.history[part.uid]).to eq nil

      job.transfer_manual_count(count)

      expect(inventory.history[part.uid]).to eq count.history_hash_for_inventory
    end
  end
end
