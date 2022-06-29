# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CountCreateJob, type: :job do
  let(:job) { CountCreateJob.new }
  let(:inventory) { create :inventory }

  it 'queues as count_create' do
    expect(job.queue_name).to eq 'count_create'
  end

  describe '#perform' do
    let(:technology_to_skip) { create :technology }
    let(:technology) { create :technology }

    context 'when a technology is not included' do
      it 'doesn\'t create counts for items exclusive to the skipped technologies' do
        3.times do
          parts_to_count = create :part
          technology.quantities[parts_to_count.uid] = 1

          create :part # no association to any tech

          part_to_skip = create :part
          technology_to_skip.quantities[part_to_skip] = 1
        end

        technology_to_skip.save
        technology.save

        inventory.technologies = [technology.id]
        inventory.save

        # take one of the maybes and share it with another technology
        parts_to_maybe_skip = technology_to_skip.quantities.keys
        technology.quantities[parts_to_maybe_skip.pop] = 1

        job.perform(inventory)

        count_uids = Inventory.latest.counts.map { |c| c.item.uid }

        parts_to_maybe_skip.each do |p_uid|
          expect(count_uids).not_to include p_uid
        end
        expect(count_uids).to include technology.uid
        expect(count_uids).not_to include technology_to_skip.uid
      end
    end

    it 'calls create_count for each item in the system' do
      3.times do
        part = create :part
        technology.quantities[part.uid] = 1
        create :part
      end
      technology.save
      inventory.technologies = [technology.id]
      inventory.save

      expect(job).to receive(:create_count).exactly(4).times

      job.perform(inventory)
    end
  end

  describe '#create_count' do
    it 'creates a Count record from an item record' do
      part = create :part

      job.inventory = inventory

      expect { job.create_count(part) }
        .to change { Count.all.size }
        .from(0).to(1)
    end
  end
end
