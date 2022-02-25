# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_examples Itemable do
  let(:item) { create described_class.name.downcase.to_sym }

  describe '#all_technologies' do
    context 'when item is a Technology' do
      it 'returns []' do
        expect(item.all_technologies).to eq [] if item.is_a? Technology
      end
    end

    context 'when item is not a Technology' do
      it 'looks for matches in all active Technology quantities JSON fields' do
        unless item.is_a? Technology
          expect(Technology).to receive_message_chain(:kept, :where).with('quantities ? :key', key: item.uid)
          item.all_technologies
        end
      end
    end
  end

  describe '#all_technologies_names' do
    context 'when item is a Technology' do
      it 'returns short_name' do
        expect(item.all_technologies_names).to eq item.short_name if item.is_a? Technology
      end
    end

    context 'when item is not a Technology' do
      it 'plucks and joins short_names from  all_technologies' do
        unless item.is_a? Technology
          expect(item).to receive_message_chain(:all_technologies, :active, :pluck, :join)

          item.all_technologies_names
        end
      end
    end
  end

  describe '#all_technologies_ids' do
    context 'when item is a Technology' do
      it 'returns item.id' do
        expect(item.all_technologies_ids).to eq item.id if item.is_a? Technology
      end
    end

    context 'when item is not a Technology' do
      it 'plucks and joins IDs from all_technologies' do
        unless item.is_a? Technology
          expect(item).to receive_message_chain(:all_technologies, :active, :pluck, :join)

          item.all_technologies_ids
        end
      end
    end
  end

  describe 'has_sub_assemblies?' do
    context 'when item is a Material' do
      it 'returns false' do
        expect(item.has_sub_assemblies?).to eq false if item.is_a? Material
      end
    end

    context 'when item is a Part' do
      it 'returns made_from_material?' do
        expect(item.has_sub_assemblies?).to eq item.made_from_material? if item.is_a? Part
      end
    end

    context 'when item is a Technology or Component' do
      it 'calls assemblies.any?' do
        if [Technology, Component].include? item.class
          expect(item).to receive_message_chain(:assemblies, :any?)

          item.has_sub_assemblies?
        end
      end
    end
  end

  describe '#history_only' do
    context 'when item\'s history is empty' do
      it 'returns an empty hash' do
        item.history = {}

        expect(item.history_only('box')).to eq Hash.new
      end
    end

    context 'when given a bad key name' do
      it 'returns nil' do
        item.history = JSON.parse(File.read("#{Rails.root}/spec/fixtures/files/item_history_spec.json"))

        expect(item.history_only('badbad')).to eq nil
      end
    end

    it 'takes a key name and returns only that specific value from the history hash' do
      item.history = JSON.parse(File.read("#{Rails.root}/spec/fixtures/files/item_history_spec.json"))

      expect(item.history_only('box').size).to eq 6
    end
  end

  describe '#history_series' do
    context 'when item\'s history is blank' do
      it 'returns []' do
        item.history = {}

        expect(item.history_series).to eq []
      end
    end

    it 'returns an array of hashes' do
      item.history = JSON.parse(File.read("#{Rails.root}/spec/fixtures/files/item_history_spec.json"))

      expect(item.history_series.size).to eq 3
    end
  end

  describe '#label_hash' do
    it 'returns a hash of attributes important to Label' do
      label_hash = item.label_hash

      expect(label_hash.keys).to eq %i[name description uid technologies quantity_per_box picture only_loose]
    end
  end

  describe '#picture' do
    let(:image_double) { instance_double ActiveStorage::Attached::One }

    context 'when an image is attached' do
      it 'returns an image object' do
        allow(item).to receive(:image).and_return(image_double)
        allow(image_double).to receive(:attached?).and_return(true)

        expect(item.picture).to eq image_double
      end
    end

    context 'when an image is not attached' do
      it 'returns a string URL for placeholder pictures' do
        expect(item.picture.class).to eq String
      end
    end
  end

  describe '#quantity' do
    it 'passes the given UID to quantities' do
      item.quantities['M006'] = 0.08124

      expect(item.quantity('M006')).to eq 0.08124
    end
  end

  describe '#quantities_with_tech_names_short' do
    let(:technology) { create :technology, short_name: 'short name' }

    context 'when item is not a Technology' do
      it 'returns []' do
        expect(item.quantities_with_tech_names_short).to eq [] unless item.is_a? Technology
      end
    end

    context 'when item is a Technology' do
      it 'returns an array of short tech names and quantities' do
        if item.is_a? Technology
          item.quantities[technology.uid] = 3

          expect(item.quantities_with_tech_names_short).to eq [['short name', 3]]
        end
      end
    end
  end

  private

  describe '#check_uid' do
    it 'fires on after_save' do
      expect(item).to receive(:check_uid)

      item.save
    end

    context 'when uid is blank' do
      it 'calls update_columns' do
        former_uid = item.uid
        item.uid = nil

        expect(item).to receive(:update_columns).with(uid: former_uid)

        item.save
      end
    end

    context 'when uid is not logically derived from ID' do
      it 'calls update_columns' do
        former_uid = item.uid
        item.uid = "#{item.class.name[0]}966996"

        expect(item).to receive(:update_columns).with(uid: former_uid)

        item.save
      end
    end

    context 'when uid is not logically derived from item type' do
      it 'calls update_columns' do
        former_uid = item.uid
        item.uid = item.uid.gsub(/^\w/, 'Q')

        expect(item).to receive(:update_columns).with(uid: former_uid)

        item.save
      end
    end

    context 'when uid is not wrong' do
      it 'doesn\'t call update update_columns' do
        expect(item).to receive(:check_uid)
        expect(item).not_to receive(:update_columns)

        item.save
      end
    end
  end

  describe '#run_price_calculation_job' do
    let(:ar_relation) { instance_double ActiveRecord::Relation }

    context 'when price_cents changed on last save' do
      it 'fires on after_save' do
        item.price_cents = 699_669

        expect(item).to receive(:run_price_calculation_job)

        item.save
      end
    end

    it 'calls delete_all on existing PriceCalculationJobs that haven\'t run yet' do
      ar_relation = instance_double ActiveRecord::Relation
      allow(Delayed::Job).to receive(:where).and_return(ar_relation)
      allow(ar_relation).to receive(:delete_all)

      expect(Delayed::Job).to receive(:where).with(queue: 'price_calc', locked_at: nil)
      expect(ar_relation).to receive(:delete_all)

      item.__send__(:run_price_calculation_job)
    end

    it 'queues up a PriceCalculationJob' do
      allow(Delayed::Job).to receive_message_chain(:where, :delete_all)

      expect(PriceCalculationJob).to receive(:perform_later)

      item.__send__(:run_price_calculation_job)
    end
  end

  describe '#run_update_jobs' do
    it 'calls delete_all on existing ProduceableJobs and GoalRemainderCalculationJobs that haven\'t run yet' do
      ar_relation = instance_double ActiveRecord::Relation
      allow(Delayed::Job).to receive(:where).and_return(ar_relation)
      allow(ar_relation).to receive(:delete_all)

      expect(Delayed::Job).to receive(:where).with(queue: %w[produceable goal_remainder], locked_at: nil)
      expect(ar_relation).to receive(:delete_all)

      item.__send__(:run_update_jobs)
    end

    it 'queues up a ProduceableJob' do
      allow(item).to receive(:run_jobs_related_to_quantity_from_material).and_return(true) if item.instance_of?(Part)

      allow(Delayed::Job).to receive_message_chain(:where, :delete_all)

      expect { item.__send__(:run_update_jobs) }
        .to have_enqueued_job(ProduceableJob)
    end

    it 'queues up a GoalRemainderCalculationJob' do
      allow(item).to receive(:run_jobs_related_to_quantity_from_material).and_return(true) if item.instance_of?(Part)

      allow(Delayed::Job).to receive_message_chain(:where, :delete_all)

      expect { item.__send__(:run_update_jobs) }
        .to have_enqueued_job(GoalRemainderCalculationJob)
    end

    context 'when #saving_via_count_transfer_job is' do
      it 'not true, it fires after_update' do
        expect(item.saving_via_count_transfer_job).to eq nil
        expect(item).to receive(:run_update_jobs)

        item.update(loose_count: 26)
      end

      it 'true, it does not fire after_update' do
        item.saving_via_count_transfer_job = true

        expect(item).not_to receive(:run_update_jobs)

        item.update(loose_count: 26)
      end
    end

    # Not bothering to test the other conditions:
    # saved_change_to_loose_count? || saved_change_to_box_count? || saved_change_to_quantity_per_box?
  end

  describe '#set_below_minimum' do
    it 'fires on before_save' do
      expect(item).to receive(:set_below_minimum)

      item.save
    end

    it 'sets the below_miminum boolean based upon available and minimum_on_hand' do
      item.below_minimum = false
      item.minimum_on_hand = 35
      item.available_count = 34
      item.__send__(:set_below_minimum)

      expect(item.below_minimum?).to eq true

      item.available_count = 36
      item.__send__(:set_below_minimum)

      expect(item.below_minimum?).to eq false
    end
  end

  describe '#update_available_count' do
    context 'when loose_count, box_count, or quantity_per_box are about to change' do
      it 'fires on before_save' do
        expect(item).to receive(:update_available_count).exactly(3).times

        item.update(loose_count: 5)
        item.update(box_count: 4)
        item.update(quantity_per_box: 150)
        item.update(name: 'Yowza')
      end
    end

    it 'sets the available_count based upon box and loose counts' do
      item.available_count = nil
      item.box_count = 5
      item.quantity_per_box = 100
      item.loose_count = 30

      item.__send__(:update_available_count)

      expect(item.available_count).to eq 530
    end
  end
end
