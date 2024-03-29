# frozen_string_literal: true

require 'rails_helper'

RSpec.describe QuantityAndDepthCalculationJob, type: :job do
  let(:job) { QuantityAndDepthCalculationJob.new }

  it 'queues as quantity_calc' do
    expect(job.queue_name).to eq 'quantity_calc'
  end

  describe '#perform' do
    it 'calls set_all_assembly_depths_to_zero' do
      expect(job).to receive(:set_all_assembly_depths_to_zero)

      job.perform
    end

    it 'calls set_all_item_quantities_to_zero' do
      expect(job).to receive(:set_all_item_quantities_to_zero)

      job.perform
    end

    context 'for each technology' do
      let(:techs) { create_list :technology, 3 }

      it 'calls process_technology' do
        techs

        expect(job).to receive(:process_technology).exactly(3).times

        job.perform
      end

      it 'calls insert_into_item_quantities' do
        techs.each do |tech|
          tech.update(quantities: { k: 'v' })
        end

        allow(job).to receive(:process_technology).and_return(true)

        expect(job).to receive(:insert_into_item_quantities).exactly(3).times

        job.perform
      end
    end
  end

  describe '#process_technology' do
    let(:technology) { create :technology }
    let(:assemblies) { create_list :assembly_part_from_material, 3, combination: technology }

    it 'calls assemblies_loop' do
      job.technology = technology

      expect(job).to receive(:assemblies_loop).with(technology.assemblies)

      job.process_technology
    end

    it 'calls loop_parts_for_material' do
      job.technology = technology
      assemblies

      expect(job).to receive(:loop_parts_for_materials)

      job.process_technology
    end
  end

  describe '#assemblies_loop' do
    let(:technology) { create :technology }
    let(:assemblies) { create_list :assembly_tech, 3, combination: technology, depth: 2 }

    context 'when the counter is greater than the current assembly\'s depth' do
      let(:counter) { 4 }

      it 'calls update_columns on the assembly' do
        job.counter = counter

        allow(job).to receive(:insert_into_quantity).and_return(true)

        assemblies.each do |assembly|
          expect(assembly).to receive(:update_columns).with(depth: counter)
        end

        job.assemblies_loop(assemblies)
      end
    end

    context 'when the counter is smaller than the current assembly\'s depth' do
      let(:counter) { 1 }

      it 'does not call update_columns on the assembly' do
        job.counter = counter

        allow(job).to receive(:insert_into_quantity).and_return(true)

        assemblies.each do |assembly|
          expect(assembly).not_to receive(:update_columns)
        end

        job.assemblies_loop(assemblies)
      end
    end

    context 'when the assembly.item is a part made from materials' do
      let(:assemblies) { create_list :assembly_part_from_material, 3, combination: technology, depth: 4 }

      it 'adds the id to @part_ids_made_from_materials' do
        job.counter = 3
        job.part_ids_made_from_material = []

        allow(job).to receive(:insert_into_quantity).and_return(true)
        allow(job).to receive(:loop_components).and_return(true)

        expect(job.part_ids_made_from_material.blank?).to eq true

        job.assemblies_loop(assemblies)

        expect(job.part_ids_made_from_material.size).to eq 3
      end
    end

    context 'if any assemblies items are components' do
      it 'calls loop_components' do
        job.counter = 3

        allow(job).to receive(:insert_into_quantity).and_return(true)

        expected_hash = {}
        assemblies.each do |a|
          expected_hash[a.item_id] = a.quantity
        end

        expect(job).to receive(:loop_components).with(expected_hash)

        job.assemblies_loop(assemblies)
      end
    end
  end

  describe '#insert_into_quantity' do
    let(:technology) { create :technology }
    let(:part) { create :part }
    let(:assembly) { create :assembly, combination: technology, item: part, quantity: 5 }

    context 'when the item.uid is already in the @technology.quantities hash' do
      before do
        technology.update(quantities: { part.uid => 2 })
      end

      it 'combines the value' do
        job.technology = technology

        expect { job.insert_into_quantity(assembly.item.uid, assembly.quantity) }
          .to change { technology.quantities[part.uid] }
          .from(2).to(7)
      end
    end

    context 'when the item.uid is not in the @technology.quantities hash' do
      it 'adds the value' do
        job.technology = technology

        expect { job.insert_into_quantity(assembly.item.uid, assembly.quantity) }
          .to change { technology.quantities[part.uid] }
          .from(nil).to(5)
      end
    end
  end

  describe '#insert_into_item_quantities' do
    let(:value) { 4 }
    let(:technology) { create :technology }
    let(:part) { create :part }

    it 'adds the value to the item.quantities hash under the @technology.uid' do
      job.technology = technology

      expect { job.insert_into_item_quantities(part.uid, value) }
        .to change { part.reload.quantities[technology.uid] }
        .from(nil).to(4)
    end
  end

  describe '#loop_components' do
    let(:components) { create_list :component, 4 }

    it 'calls assemblies_loop on a collection of components' do
      components_hash = {}

      components.each do |comp|
        components_hash[comp.id] = Random.rand(2..45)
      end
      job.counter = 1

      expect(job).to receive(:assemblies_loop).exactly(4).times

      job.loop_components(components_hash)
    end
  end

  describe '#loop_parts_for_materials' do
    let(:technology) { create :technology }
    let(:part) { create :part_from_material, quantity_from_material: 4 }

    context 'when @technology.quantities already has a hash value' do
      before do
        technology.quantities[part.uid] = 1
        technology.quantities[part.material.uid] = 2
        technology.save
        job.part_ids_made_from_material = [part.id]
      end

      it 'combines the value' do
        job.technology = technology

        expect { job.loop_parts_for_materials }
          .to change { technology.quantities[part.material.uid] }
          .from(2).to(2.25)
      end
    end

    context 'when @technology.quantities doesn\'t have a hash value' do
      before do
        technology.quantities[part.uid] = 2
        technology.save
        job.part_ids_made_from_material = [part.id]
      end

      it 'adds the value' do
        job.technology = technology

        expect { job.loop_parts_for_materials }
          .to change { technology.quantities[part.material.uid] }
          .from(nil).to(0.5)
      end
    end
  end

  describe '#set_all_assembly_depths_to_zero' do
    it 'calls Assembly.update_all' do
      expect(Assembly).to receive(:update_all).with(depth: 0)

      job.set_all_assembly_depths_to_zero
    end
  end

  describe '#set_all_item_quantities_to_zero' do
    it 'calls Component.update_all' do
      expect(Component).to receive(:update_all).with(quantities: {})

      job.set_all_item_quantities_to_zero
    end

    it 'calls Part.update_all' do
      expect(Part).to receive(:update_all).with(quantities: {})

      job.set_all_item_quantities_to_zero
    end

    it 'calls Material.update_all' do
      expect(Material).to receive(:update_all).with(quantities: {})

      job.set_all_item_quantities_to_zero
    end
  end
end
