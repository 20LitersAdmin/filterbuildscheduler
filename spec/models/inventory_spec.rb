# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Inventory, type: :model do
  let(:inventory) { create :inventory }
  let(:manual) { build :inventory }
  let(:shipping) { build :inventory_ship }
  let(:receiving) { build :inventory_rec }
  let(:event) { build :inventory_event }

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
    end
  end

  describe '#type_for_params' do
    it 'returns a string indicating the type of event' do
      expect(receiving.type_for_params).to eq('receiving')
      expect(shipping.type_for_params).to eq('shipping')
      expect(event.type_for_params).to eq('event')
      expect(manual.type_for_params).to eq('manual')
    end
  end

  describe '#verb_past_tense' do
    it 'returns a string indicating the type of event' do
      expect(event.verb_past_tense).to eq('adjusted after an event')
      expect(receiving.verb_past_tense).to eq('received')
      expect(shipping.verb_past_tense).to eq('shipped')
      expect(manual.verb_past_tense).to eq('counted')
    end
  end

  private

  describe '#item_count' do
    let(:user) { create :user }

    it 'returns the number of counts that have a user_id' do
      create_list(:count, 4, inventory: inventory, user: user)
      create_list(:count_comp, 3, inventory: inventory, user: user)
      create_list(:count_mat, 2, inventory: inventory, user: user)

      create_list(:count, 7, inventory: inventory)
      create_list(:count_comp, 6, inventory: inventory)
      create_list(:count_mat, 5, inventory: inventory)

      expect(inventory.__send__(:item_count)).to eq(9)
    end
  end

  describe '#run_produceable_job' do
    before :each do
      allow(Delayed::Job)
        .to receive(:where)
        .with(queue: 'produceable', locked_at: nil)
        .and_call_original

      allow_any_instance_of(ActiveRecord::Relation)
        .to receive(:delete_all)
        .and_return(1)
    end

    it 'fires on after_update' do
      expect(inventory).to receive(:run_produceable_job)

      inventory.update(date: Date.yesterday)
    end

    context 'when inventory.completed_at is nil' do
      it "doesn't fire" do
        expect(inventory.completed_at).to eq nil

        expect(Delayed::Job).not_to receive(:where)

        inventory.__send__(:run_produceable_job)
      end
    end

    context 'when inventory.completed_at is not nil' do
      it 'fires' do
        inventory.completed_at = Time.now

        expect(Delayed::Job).to receive(:where)

        inventory.__send__(:run_produceable_job)
      end
    end

    it 'deletes any currently queued Produceable jobs' do
      inventory.completed_at = Time.now

      expect_any_instance_of(ActiveRecord::Relation).to receive(:delete_all)

      inventory.__send__(:run_produceable_job)
    end

    it 'queues up an instance of Produceable job' do
      inventory.completed_at = Time.now

      expect { inventory.__send__(:run_produceable_job) }
        .to change { Delayed::Job.where(queue: 'produceable', locked_at: nil).size }
        .from(0).to(1)
    end
  end

  describe '#run_count_transfer_job' do
    before :each do
      allow(Delayed::Job)
        .to receive(:where)
        .with(queue: 'count_transfer', locked_at: nil)
        .and_call_original

      allow_any_instance_of(ActiveRecord::Relation)
        .to receive(:delete_all)
        .and_return(1)
    end

    it 'fires on after_update' do
      expect(inventory).to receive(:run_count_transfer_job)

      inventory.update(date: Date.yesterday)
    end

    context 'when inventory.completed_at is nil' do
      it "doesn't fire" do
        expect(inventory.completed_at).to eq nil

        expect(Delayed::Job).not_to receive(:where)

        inventory.__send__(:run_count_transfer_job)
      end
    end

    context 'when inventory.completed_at is not nil' do
      it 'fires' do
        inventory.completed_at = Time.now

        expect(Delayed::Job).to receive(:where)

        inventory.__send__(:run_count_transfer_job)
      end
    end

    it 'deletes any currently queued CountTransfer jobs' do
      inventory.completed_at = Time.now

      expect_any_instance_of(ActiveRecord::Relation).to receive(:delete_all)

      inventory.__send__(:run_count_transfer_job)
    end

    it 'queues up an instance of count_transfer job' do
      inventory.completed_at = Time.now

      expect { inventory.__send__(:run_count_transfer_job) }
        .to change { Delayed::Job.where(queue: 'count_transfer', locked_at: nil).size }
        .from(0).to(1)
    end
  end
end
