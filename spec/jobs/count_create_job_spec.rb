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
    let(:technologies_params) { ActionController::Parameters.new(technologies: ['T009', 'T007', technology_to_skip.uid.to_s]) }

    context 'when technologies_params includes technologies' do
      let(:technology_to_include) { create :technology }

      it 'pulls technologies excluding those UIDs' do
        expect(Technology).to receive_message_chain(:list_worthy, :where, :not)
          .with(uid: ['T009', 'T007', technology_to_skip.uid.to_s])
          .and_return(Technology.where(uid: technology_to_include.uid))

        job.perform(inventory, technologies_params)
      end
    end

    it 'returns early if no technologies are found' do
      expect(Technology).to receive_message_chain(:list_worthy, :where, :not)
        .with(uid: ['T009', 'T007', technology_to_skip.uid.to_s])
        .and_return(Technology.none)

      expect(job.perform(inventory, technologies_params)).to eq nil
    end

    it 'calls create_count for itself and each key in quantities' do
      technology = create :technology
      3.times do
        part = create :part
        technology.quantities[part.uid] = 1
      end
      technology.save

      expect(job).to receive(:create_count).exactly(4).times

      job.perform(inventory, technologies_params)
    end
  end

  describe '#create_count' do
    context 'when item is nil' do
      it 'returns early' do
        expect(job.create_count(nil)).to eq nil
      end
    end

    it 'creates a Count record from an item record' do
      part = create :part

      job.inventory = inventory

      expect { job.create_count(part) }
        .to change { Count.all.size }
        .from(0).to(1)
    end
  end
end
