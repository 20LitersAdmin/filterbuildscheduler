# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PriceCalculationJob, type: :job do
  let(:job) { PriceCalculationJob.new }
  let(:ar_relation) { instance_double ActiveRecord::Relation }

  it 'queues as price_calc' do
    expect(job.queue_name).to eq 'price_calc'
  end

  describe '#perform' do
    let(:part) { create :part_from_material }

    it 'calls Technology.update_all' do
      expect(Technology).to receive(:update_all).with(price_cents: 0)

      job.perform
    end

    it 'calls Component.update_all' do
      expect(Component).to receive(:update_all).with(price_cents: 0)

      job.perform
    end

    it 'calls Part.made_from_material.update_all' do
      allow(Part).to receive(:made_from_material).and_return(ar_relation)
      allow(ar_relation).to receive(:update_all).with(price_cents: 0)
      allow(ar_relation).to receive(:each).and_yield(part)

      expect(ar_relation).to receive(:update_all).with(price_cents: 0)

      job.perform
    end

    it 'calls set_prices_for_parts_made_from_materials' do
      expect(job).to receive(:set_prices_for_parts_made_from_materials)

      job.perform
    end

    it 'calls sum_prices_for_assembly_combinations' do
      expect(job).to receive(:sum_prices_for_assembly_combinations)

      job.perform
    end
  end

  describe '#set_prices_for_parts_made_from_materials' do
    let(:material) { create :material, price_cents: 2_500 }
    let(:part) { create :part_from_material, material: material, price_cents: 0, quantity_from_material: 25 }

    context 'if a part has quantity_from_material.nil? or .zer?' do
      before do
        allow(Part).to receive(:made_from_material).and_return(ar_relation)
        allow(ar_relation).to receive(:each).and_yield(part)
        part.quantity_from_material = 0
      end

      it '"puts" an error' do
        expect { job.set_prices_for_parts_made_from_materials }
          .to output(a_string_including("*** #{part.uid} has no quantity_from_material!!! It was skipped ***")).to_stdout
      end
    end

    it 'sets a price for the part based upon the material price' do
      expect { job.set_prices_for_parts_made_from_materials }
        .to change { part.reload.price_cents }
        .from(0).to(100)
    end
  end

  describe '#sum_prices_for_assembly_combinations' do
    let(:component) { create :component, price_cents: 0 }
    let(:part) { create :part, price_cents: 20 }
    let(:assembly) { create :assembly, quantity: 2, item: part, combination: component }

    it 'calls Assembly.descending' do
      allow(Assembly).to receive(:descending).and_return(ar_relation)
      allow(ar_relation).to receive(:each).and_yield(assembly)

      expect(Assembly).to receive(:descending)

      job.sum_prices_for_assembly_combinations
    end

    context 'for a given assembly' do
      before do
        allow(Assembly).to receive(:descending).and_return(ar_relation)
        allow(ar_relation).to receive(:each).and_yield(assembly)
      end

      it 'calls assembly.update_columns to recalculate price_cents' do
        # Itemable has an after_save that triggers PriceCalculationJob
        # while probably not bad for testing, worth skipping callbacks
        part.update_columns(price_cents: 40)

        allow(assembly).to receive(:update_columns).and_call_original

        expect(assembly).to receive(:update_columns)

        expect { job.sum_prices_for_assembly_combinations }
          .to change { assembly.reload.price_cents }
          .from(40).to(80)
      end

      it 'calls combination.update_columns to set a new price' do
        allow(assembly).to receive(:combination).and_return(component)
        allow(component).to receive(:update_columns).and_call_original

        expect(component).to receive(:update_columns).with(price_cents: 40)

        expect { job.sum_prices_for_assembly_combinations }
          .to change { component.reload.price_cents }
          .from(0).to(40)
      end
    end
  end
end
