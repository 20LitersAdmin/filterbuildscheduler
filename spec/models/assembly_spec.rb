# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Assembly, type: :model do
  # let(:part) { create :part }
  # let(:component) { create :component }
  # let(:assembly) { build :assembly, item: part, combination: component }
  let(:assembly) { build :assembly }

  describe 'must be valid' do
    let(:no_combination) { build :assembly, combination: nil }
    let(:no_item) { build :assembly, item: nil }
    let(:no_quantity) { build :assembly, quantity: nil }
    let(:zero_quantity) { build :assembly, quantity: 0 }
    let(:negative_quantity) { build :assembly, quantity: -5 }
    let(:negative_price) { build :assembly, price_cents: -420 }

    it 'in order to save' do
      expect(assembly.save).to eq true

      expect { no_combination.save!(validate: false) }
        .to raise_error ActiveRecord::NotNullViolation

      expect(no_item.save).to eq false
      expect(no_item.errors.messages[:item]).to eq ['must exist']

      expect(no_quantity.save).to eq false
      expect(no_quantity.errors.messages[:quantity]).to eq ['is not a number']

      expect(zero_quantity.save).to eq false
      expect(zero_quantity.errors.messages[:quantity]).to eq ['must be greater than 0']
    end

    it 'quantity can\'t be negative' do
      expect(negative_quantity.save).to be_falsey
      expect(negative_quantity.errors.messages[:quantity]).to eq ['must be greater than 0']
    end

    it 'price can\'t be negative' do
      expect(negative_price.save).to be_falsey
      expect(negative_price.errors.messages[:price]).to eq ['must be greater than or equal to 0']
    end
  end

  describe '#combination_uid' do
    it 'returns the UID of the combination' do
      expect(assembly.combination_uid).to eq assembly.combination.uid
    end

    it 'doesn\'t rely on loading the associated model' do
      expect(assembly).to_not receive(:combination)

      assembly.combination_uid
    end
  end

  describe '#has_sub_items?' do
    context 'when item_type == Part' do
      it 'calls item.made_from_material?' do
        expect(assembly.item).to receive(:made_from_material?)

        assembly.has_sub_items?
      end

      it 'is the same as calling assembly.item.made_from_material?' do
        expect(assembly.has_sub_items?).to eq assembly.item.made_from_material?
      end
    end

    context 'when item_type != Part' do
      let(:assembly_w_subs) { create :assembly_tech }
      let(:sub_item_one) { create :assembly_comps, combination: assembly_w_subs.item }
      let(:sub_item_two) { create :assembly, combination: assembly_w_subs.item }

      let(:assembly_wo_subs) { create :assembly_tech }

      it 'returns true if any Assemblies exist that have assembly.item as their combination' do
        assembly_w_subs
        sub_item_one
        sub_item_two
        assembly_wo_subs

        expect(assembly_w_subs.has_sub_items?).to be_truthy

        expect(assembly_wo_subs.has_sub_items?).to be_falsey
      end
    end
  end

  describe '#item_uid' do
    it 'returns the UID of the item' do
      expect(assembly.item_uid).to eq assembly.item.uid
    end

    it 'doesn\'t rely on loading the associated model' do
      expect(assembly).to_not receive(:item)

      assembly.item_uid
    end
  end

  describe '#name' do
    it 'returns a string' do
      expect(assembly.name.class).to eq String
    end
  end

  describe '#name_long' do
    it 'returns a string' do
      expect(assembly.name_long.class).to eq String
    end
  end

  describe '#quantity_hint' do
    it 'returns a string' do
      expect(assembly.quantity_hint.class).to eq String
    end
  end

  describe '#sub_assemblies' do
    context 'when item_type == Part' do
      it 'returns Assembly.none' do
        expect(assembly.sub_assemblies).to eq Assembly.none
      end
    end

    context 'when item_type != Part' do
      let(:assembly_w_subs) { create :assembly_tech }
      let(:sub_item_one) { create :assembly_comps, combination: assembly_w_subs.item }
      let(:sub_item_two) { create :assembly, combination: assembly_w_subs.item }

      let(:assembly_wo_subs) { create :assembly_tech }

      it 'returns a collection of Assemblies that have assembly.item as their combination' do
        expect(assembly_w_subs.sub_assemblies).to include sub_item_one
        expect(assembly_w_subs.sub_assemblies).to include sub_item_two
        expect(assembly_w_subs.sub_assemblies).not_to include assembly
        expect(assembly_w_subs.sub_assemblies).not_to include assembly_wo_subs

        expect(assembly_wo_subs.sub_assemblies.size).to eql 0
      end
    end
  end

  describe '#sub_component_assemblies' do
    context 'when item_type == Part' do
      it 'returns Assembly.none' do
        expect(assembly.sub_component_assemblies).to eq Assembly.none
      end
    end

    context 'when item_type != Part' do
      let(:assembly_w_subs) { create :assembly_tech }
      let(:sub_item_one) { create :assembly_comps, combination: assembly_w_subs.item }
      let(:sub_item_two) { create :assembly, combination: assembly_w_subs.item }
      let(:sub_item_three) { create :assembly_comps, combination: assembly_w_subs.item }

      let(:assembly_wo_subs) { create :assembly_tech }

      it 'returns a collection of Assemblies that have assembly.item as their combination with an item_type of Component' do
        expect(assembly_w_subs.sub_component_assemblies).to include sub_item_one
        expect(assembly_w_subs.sub_component_assemblies).not_to include sub_item_two
        expect(assembly_w_subs.sub_component_assemblies).to include sub_item_three
        expect(assembly_w_subs.sub_component_assemblies).not_to include assembly
        expect(assembly_w_subs.sub_component_assemblies).not_to include assembly_wo_subs

        expect(assembly_wo_subs.sub_component_assemblies.size).to eql 0
      end
    end
  end

  describe '#super_assemblies' do
    context 'when combination_type == Technology' do
      it 'returns Assembly.none' do
        expect(assembly.super_assemblies.size).to eq 0
      end
    end

    context 'when combination_type != Technology' do
      let(:assembly_w_supers) { create :assembly }
      let(:super_item_one) { create :assembly_comps, item: assembly_w_supers.combination }
      let(:super_item_two) { create :assembly_tech, item: assembly_w_supers.combination }

      it 'returns a collection of Assemblies that have assembly.combination as their item' do
        assembly_w_supers
        super_item_one
        super_item_two

        expect(assembly_w_supers.super_assemblies).to include super_item_one
        expect(assembly_w_supers.super_assemblies).to include super_item_two
        expect(assembly_w_supers.super_assemblies).not_to include assembly
      end
    end
  end

  describe '#types' do
    it 'returns a string' do
      expect(assembly.types.class).to eq String
    end
  end

  private

  describe '#calculate_price' do
    it 'fires on before_save' do
      expect(assembly).to receive(:calculate_price)

      assembly.save
    end

    it 'sets the records price_cents to match the item\'s price_cents times the quantity' do
      assembly.price_cents = 0
      assembly.item.price_cents = 69

      expect(assembly.price_cents).not_to eq((assembly.item.price_cents * assembly.quantity))

      assembly.save

      expect(assembly.price_cents).to eq((assembly.item.price_cents * assembly.quantity))
    end
  end

  describe '#update_items_via_jobs' do
    it 'fires on after_save' do
      expect(assembly).to receive(:update_items_via_jobs)

      assembly.save
    end

    it 'fires on after_destroy' do
      expect(assembly).to receive(:update_items_via_jobs)

      assembly.destroy
    end

    it 'enqueues QuantityAndDeptCalculationJob' do
      allow(assembly.item).to receive(:run_update_jobs).and_return true
      allow(assembly.combination).to receive(:run_update_jobs).and_return true

      expect { assembly.__send__(:update_items_via_jobs) }
        .to have_enqueued_job(QuantityAndDepthCalculationJob)
    end

    it 'enqueues PriceCalculationJob' do
      allow(assembly.item).to receive(:run_update_jobs).and_return true
      allow(assembly.combination).to receive(:run_update_jobs).and_return true

      expect { assembly.__send__(:update_items_via_jobs) }
        .to have_enqueued_job(PriceCalculationJob)
    end

    it 'enqueues ProduceableJob' do
      allow(assembly.item).to receive(:run_update_jobs).and_return true
      allow(assembly.combination).to receive(:run_update_jobs).and_return true

      expect { assembly.__send__(:update_items_via_jobs) }
        .to have_enqueued_job(ProduceableJob)
    end
  end
end
