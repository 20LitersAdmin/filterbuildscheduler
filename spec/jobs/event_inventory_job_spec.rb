# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventInventoryJob, type: :job do
  let(:job) { EventInventoryJob.new }
  let(:technology) { create :technology, quantity_per_box: 10 }
  let(:event) { create :complete_event, technology: technology }

  it 'queues as event_inventory' do
    expect(job.queue_name).to eq 'event_inventory'
  end

  describe '#perform' do
    context 'when event has no results' do
      it 'returns false' do
        event.technologies_built = 0
        event.boxes_packed = 0

        expect(job.perform(event)).to eq false
      end
    end

    context 'when event already has an inventory' do
      it 'returns false' do
        create :inventory_event, event: event
        event.reload

        expect(job.perform(event)).to eq false
      end
    end

    it 'creates an inventory via Event.create_inventory' do
      allow(event).to receive(:create_inventory).and_call_original

      expect(event).to receive(:create_inventory).with(date: Date.today)

      job.perform(event)
    end

    context 'when technology has sufficient count' do
      it 'calls create_technology_count_only and returns true' do
        # Factorybot event produces 30 loose, 1 box
        technology.update(loose_count: 31, box_count: 2)

        expect(job).to receive(:create_technology_count_only)
        expect(job.perform(event)).to eq true
      end
    end

    context 'when technology is not sufficient' do
      it 'calls create_technology_count' do
        # Factorybot event produces 30 loose, 1 box
        technology.update(loose_count: 9, box_count: 0)

        expect(job).to receive(:create_technology_count)

        job.perform(event)
      end

      it 'calls loop_assemblies' do
        technology.update(loose_count: 9, box_count: 0)

        expect(job).to receive(:loop_assemblies)

        job.perform(event)
      end
    end

    it 'calls inventory.update to trigger CountTransferJob' do
      inv_double = instance_double Inventory
      allow(event).to receive(:create_inventory).and_return(inv_double)
      allow(job).to receive(:create_count).and_return(true)

      expect(inv_double).to receive(:update)

      job.perform(event)
    end
  end

  describe '#create_count' do
    it 'creates a new count record associated to the inventory' do
      inventory = create :inventory_event

      job.inventory = inventory

      expect { job.create_count(technology, 4, 2) }.to change { inventory.counts.size }.from(0).to(1)
    end
  end

  describe '#create_technology_count' do
    it 'calculates change_to_loose and passes it to to create_count' do
      technology.loose_count = 5
      job.technology = technology
      job.loose_created = 20
      job.box_created = 2

      expect(job).to receive(:create_count).with(technology, 15, 2)

      job.create_technology_count
    end
  end

  describe '#create_technology_count_only' do
    it 'calculates new_loose_count and passes it to to create_count' do
      technology.loose_count = 5
      job.technology = technology
      job.loose_created = 40
      job.box_created = 2
      job.produced_and_boxed = 30

      expect(job).to receive(:create_count).with(technology, 10, 2)

      job.create_technology_count_only
    end
  end

  describe '#item_can_satisfy_remainder' do
    let(:part) { create :part, loose_count: 30, box_count: 5, quantity_per_box: 10 }

    context 'when there are enough loose items and no boxes needed to be opened' do
      let(:amt_to_remove) { 25 }

      it 'calls create_count with specific values' do
        expect(part.loose_count >= amt_to_remove).to eq true

        job.item = part

        expect(job).to receive(:create_count).with(part, -amt_to_remove, 0)

        job.item_can_satisfy_remainder(amt_to_remove)
      end
    end

    context 'when there are not enough loose items and boxes must be opened' do
      let(:amt_to_remove) { 65 }

      it 'calls create_count with specific values' do
        expect(part.loose_count >= amt_to_remove).to eq false

        job.item = part

        expect(job).to receive(:create_count).with(part, -25, -4)

        job.item_can_satisfy_remainder(amt_to_remove)
      end
    end
  end

  describe '#item_has_sub_assemblies' do
    let(:amt_to_remove) { 35 }

    context 'when item is a part' do
      let(:item) { create :part_from_material, available_count: 25 }

      it 'calls produce_from_materials' do
        job.item = item

        expect(job).to receive(:produce_from_material).with(item, 10)

        job.item_has_sub_assemblies(amt_to_remove)
      end
    end

    context 'when item is not a part' do
      let(:item) { create :component, available_count: 25 }

      it 'calls loop_assemblies' do
        job.item = item

        expect(job).to receive(:loop_assemblies).with(item, 10)

        job.item_has_sub_assemblies(amt_to_remove)
      end
    end
  end

  describe '#item_insufficient' do
    let(:item) { create :part, loose_count: 3, box_count: 1 }

    it 'creates a zero-count' do
      job.item = item

      expect(job).to receive(:create_count).with(item, -3, -1)

      job.item_insufficient
    end
  end

  describe '#loop_assemblies' do
    let(:combination) { create :component }
    let(:remainder) { 25 }
    let(:assembly_class) { class_double(Assembly) }
    let(:ar_relation) { instance_double(ActiveRecord::Relation) }
    let(:assembly_instance) { instance_double(Assembly) }

    it 'calls for a collection of Assemblies' do
      allow(Assembly).to receive_message_chain(:without_price_only, :where).and_return(ar_relation)
      allow(ar_relation).to receive(:each).and_return(assembly_instance)

      expect(Assembly).to receive_message_chain(:without_price_only, :where)

      job.loop_assemblies(combination, remainder)
    end

    context 'for a given assembly' do
      let(:part) { create :part, available_count: 51 }
      let(:assembly) { create :assembly, combination: combination, item: part, quantity: 2 }

      context 'when item can satisfy the remainder' do
        it 'calls item_can_satisfy_remainder' do
          expect(part.available_count >= (remainder * assembly.quantity))

          expect(job).to receive(:item_can_satisfy_remainder).with(50)

          job.loop_assemblies(combination, remainder)
        end
      end

      context 'when item cannot satify the remainder' do
        let(:part) { create :part, available_count: 49 }
        let(:assembly) { create :assembly, combination: combination, item: part, quantity: 2 }

        it 'calls item_insufficient' do
          expect(part.available_count < (remainder * assembly.quantity))

          expect(job).to receive(:item_insufficient)

          job.loop_assemblies(combination, remainder)
        end

        context 'but item has sub-assemblies' do
          let(:part) { create :part_from_material, available_count: 49 }
          let(:assembly) { create :assembly, combination: combination, item: part, quantity: 2 }

          it 'calls item_has_sub_assemblies' do
            allow(job).to receive(:item_insufficient).and_return(true)
            assembly
            expect(part.has_sub_assemblies?).to eq true

            expect(job).to receive(:item_has_sub_assemblies).with(50)

            job.loop_assemblies(combination, remainder)
          end
        end
      end
    end
  end

  describe '#material_can_satisfy_remainder' do
    let(:material) { create :material }
    let(:part) { create :part_from_material, material: material, quantity_from_material: 5 }
    let(:parts_needed) { 25 }

    context 'when material.loose_count >= materials needed' do
      before do
        material.loose_count = 6
      end

      it 'calls create_count for the material' do
        expect(job).to receive(:create_count).with(material, -5, 0)

        job.material_can_satisfy_remainder(part, parts_needed)
      end
    end

    context 'when material.loose_count < materials needed' do
      before do
        material.loose_count = 3
        material.box_count = 2
        material.quantity_per_box = 6
      end

      it 'calculates how many boxes of materials need to be used, then calls create_count for the material' do
        expect(job).to receive(:create_count).with(material, 1, -1)

        job.material_can_satisfy_remainder(part, parts_needed)
      end
    end

    context 'when parts produced from material > parts needed' do
      let(:inventory) { create :inventory_event }
      let(:ar_relation) { instance_double ActiveRecord::Relation }
      let(:count) { create :count, item: part, loose_count: 3 }

      it 'updates the part\'s count with the over-produced parts' do
        part.quantity_from_material = 15
        job.inventory = inventory

        allow(inventory).to receive(:counts).and_return(ar_relation)
        allow(ar_relation).to receive(:where).with(item: part).and_return(ar_relation)
        allow(ar_relation).to receive(:first).and_return(count)

        allow(job).to receive(:create_count).and_return(true)

        expect { job.material_can_satisfy_remainder(part, parts_needed) }
          .to change { count.loose_count }
          .from(3).to(8)
      end
    end
  end

  describe '#produce_from_material' do
    let(:material) { create :material }
    let(:part) { create :part_from_material, material: material, quantity_from_material: 5 }
    let(:remainder) { 25 }

    context 'when parts that can be produced >= remainder needed' do
      before do
        material.available_count = 6
      end

      it 'calls material_can_satisfy_remainder' do
        expect(job).to receive(:material_can_satisfy_remainder).with(part, remainder)

        job.produce_from_material(part, remainder)
      end
    end

    context 'when parts that can be produced < remainder needed' do
      before do
        material.loose_count = 1
        material.box_count = 2
        material.available_count = 3
      end

      it 'zeros out the material by calling create_count' do
        expect(job).to receive(:create_count).with(material, -1, -2)

        job.produce_from_material(part, remainder)
      end
    end
  end
end
