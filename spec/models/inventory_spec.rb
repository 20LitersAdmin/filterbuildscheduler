# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Inventory, type: :model do
  let(:inventory) { create :inventory }
  let(:manual) { build :inventory }
  let(:shipping) { build :inventory_ship }
  let(:receiving) { build :inventory_rec }
  let(:event) { build :inventory_event }
  let(:extrapolate) { build :inventory_extrapolate }

  describe 'must be valid' do
    let(:no_receiving) { build :inventory_rec, receiving: nil }
    let(:no_shipping) { build :inventory_ship, shipping: nil }
    let(:no_manual) { build :inventory, manual: nil }
    let(:no_date) { build :inventory, date: nil }

    it 'in order to save' do
      expect(inventory.save).to eq true
      expect { no_receiving.save!(validate: false) }
        .to raise_error ActiveRecord::NotNullViolation
      expect { no_shipping.save!(validate: false) }
        .to raise_error ActiveRecord::NotNullViolation
      expect { no_manual.save!(validate: false) }
        .to raise_error ActiveRecord::NotNullViolation
      expect { no_date.save!(validate: false) }
        .to raise_error ActiveRecord::NotNullViolation
    end
  end

  describe '#count_summary' do
    it 'returns a string' do
      expect(inventory.count_summary.class).to eq String
    end

    context 'when receiving inventory' do
      it 'includes the word received' do
        expect(receiving.count_summary).to include 'received.'
      end
    end

    context 'when shipping inventory' do
      it 'includes the word shipped' do
        expect(shipping.count_summary).to include 'shipped.'
      end
    end

    context 'when manual or event-based inventory' do
      it 'includes the word counted' do
        expect(manual.count_summary).to include 'counted.'
        expect(event.count_summary).to include 'counted.'
      end
    end
  end

  describe '#event_based?' do
    context 'when inventory is event-based' do
      it 'returns true' do
        expect(event.event_based?).to eq true
      end
    end

    context 'when inventory is not event-based' do
      it 'returns false' do
        expect(manual.event_based?).to eq false
        expect(shipping.event_based?).to eq false
        expect(receiving.event_based?).to eq false
      end
    end
  end

  describe '#name' do
    it 'returns the date and type' do
      expect(inventory.name).to include inventory.date.strftime('%-m/%-d/%y')
      expect(inventory.name).to include inventory.type
    end
  end

  describe '#type' do
    it 'returns a string indicating the type of event' do
      expect(event.type).to eq('Event Based')
      expect(receiving.type).to eq('Receiving')
      expect(shipping.type).to eq('Shipping')
      expect(manual.type).to eq('Manual')
      expect(extrapolate.type).to eq('Assembly')
    end
  end

  describe '#type_for_params' do
    it 'returns a string indicating the type of event' do
      expect(receiving.type_for_params).to eq('receiving')
      expect(shipping.type_for_params).to eq('shipping')
      expect(event.type_for_params).to eq('event')
      expect(manual.type_for_params).to eq('manual')
      expect(extrapolate.type_for_params).to eq('extrapolate')
    end
  end

  describe '#verb_past_tense' do
    it 'returns a string indicating the type of event' do
      expect(event.verb_past_tense).to eq('adjusted after an event')
      expect(receiving.verb_past_tense).to eq('received')
      expect(shipping.verb_past_tense).to eq('shipped')
      expect(manual.verb_past_tense).to eq('counted')
      expect(extrapolate.verb_past_tense).to eq('created')
    end
  end

  private

  describe '#item_count' do
    let(:user) { create :user }

    it 'returns the number of counts that have a user_id' do
      create_list(:count, 4, inventory:, user:)
      create_list(:count_comp, 3, inventory:, user:)
      create_list(:count_mat, 2, inventory:, user:)

      create_list(:count, 7, inventory:)
      create_list(:count_comp, 6, inventory:)
      create_list(:count_mat, 5, inventory:)

      expect(inventory.__send__(:item_count)).to eq(9)
    end
  end

  describe '#run_produceable_job' do
    before :each do
      @sq_instance = instance_double Sidekiq::Queue
      allow(Sidekiq::Queue).to receive(:new).and_return(@sq_instance)
      allow(@sq_instance).to receive(:clear)
    end

    context 'when inventory.completed_at is nil' do
      it "doesn't fire" do
        expect(inventory.completed_at).to eq nil

        expect { inventory.run_produceable_job }
          .not_to have_enqueued_job(ProduceableJob)
      end
    end

    context 'when inventory.completed_at is not nil' do
      it 'fires and queues up an instance of ProduceableJob' do
        inventory.completed_at = Time.now

        expect { inventory.run_produceable_job }
          .to have_enqueued_job(ProduceableJob)
      end
    end

    it 'deletes any currently queued Produceable jobs' do
      inventory.completed_at = Time.now
      expect(@sq_instance).to receive(:clear)

      inventory.run_produceable_job
    end
  end

  describe '#run_count_transfer_job' do
    context 'when inventory.completed_at is nil' do
      it "doesn't fire" do
        expect(inventory.completed_at).to eq nil

        expect { inventory.run_count_transfer_job }
          .not_to have_enqueued_job(CountTransferJob)
      end
    end

    context 'when inventory.completed_at is not nil' do
      it 'fires and queues up an instance of CountTransfer job' do
        inventory.completed_at = Time.now

        expect { inventory.run_count_transfer_job }
          .to have_enqueued_job(CountTransferJob)
      end
    end

    it 'deletes any currently queued CountTransfer jobs' do
      inventory.completed_at = Time.now
      sq_instance = instance_double Sidekiq::Queue
      allow(Sidekiq::Queue).to receive(:new).and_return(sq_instance)
      expect(sq_instance).to receive(:clear)

      inventory.run_count_transfer_job
    end
  end
end
