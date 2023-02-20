# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProduceableJob, type: :job do
  let(:job) { ProduceableJob.new }

  it 'queues as produceable' do
    expect(job.queue_name).to eq 'produceable'
  end

  describe '#perform' do
    it 'calls Component.kept.update_all' do
      allow(Component).to receive_message_chain(:kept, :where, :update_all)

      expect(Component).to receive_message_chain(:kept, :update_all).with(can_be_produced: nil)

      job.perform
    end

    it 'calls Technology.kept.update_all' do
      allow(Technology).to receive_message_chain(:kept, :where, :update_all)

      expect(Technology).to receive_message_chain(:kept, :update_all).with(can_be_produced: nil)

      job.perform
    end

    it 'calls Material.kept.with_parts.each' do
      allow(Material).to receive_message_chain(:kept, :with_parts, :each)

      expect(Material).to receive_message_chain(:kept, :with_parts)

      job.perform
    end

    context 'within Material loop' do
      it 'calls loop_parts for each material' do
        create_list :part_from_material, 3

        expect(job).to receive(:loop_parts).exactly(3).times

        job.perform
      end
    end

    it 'calls Part.kept.not_made_from_material.update_all' do
      expect(Part).to receive_message_chain(:kept, :not_made_from_material, :update_all).with(can_be_produced: 0)

      job.perform
    end

    it 'calls Assembly.without_price_only.part_items.each' do
      allow(Assembly).to receive_message_chain(:without_price_only, :part_items, :each)
      allow(Assembly).to receive_message_chain(:without_price_only, :component_items, :each)

      expect(Assembly).to receive_message_chain(:without_price_only, :part_items)

      job.perform
    end

    it 'calls Assembly.without_price_only.component_items.each' do
      allow(Assembly).to receive_message_chain(:without_price_only, :part_items, :each)
      allow(Assembly).to receive_message_chain(:without_price_only, :component_items, :each)

      expect(Assembly).to receive_message_chain(:without_price_only, :component_items)

      job.perform
    end

    context 'within Assembly loop' do
      before do
        create_list :assembly, 3
        create_list :assembly_comps, 3
      end

      it 'calls calculate_for_combination' do
        expect(job).to receive(:calculate_for_combination).exactly(6).times
        job.perform
      end
    end

    it 'resets any remaining Components back to can_be_produced: 0' do
      allow(Component).to receive_message_chain(:kept, :update_all).with(can_be_produced: nil)

      allow(Component).to receive_message_chain(:kept, :where).with(can_be_produced: nil)

      expect(Component).to receive_message_chain(:kept, :where, :update_all).with(can_be_produced: 0)

      job.perform
    end

    it 'resets any remaining Technologies back to can_be_produced: 0' do
      allow(Technology).to receive_message_chain(:kept, :update_all).with(can_be_produced: nil)

      allow(Technology).to receive_message_chain(:kept, :where).with(can_be_produced: nil)

      expect(Technology).to receive_message_chain(:kept, :where, :update_all).with(can_be_produced: 0)

      job.perform
    end
  end

  describe '#calculate_for_combination' do
    let(:component) { create :component }
    let(:part) { create :part }
    let(:assembly) { create :assembly, combination: component, item: part, quantity: 2 }

    context 'when combination.can_be_produced is nil' do
      before do
        component.can_be_produced = nil
      end

      it 'calls combination.update_columns' do
        expect(component).to receive(:update_columns)

        job.calculate_for_combination(assembly)
      end
    end

    context 'when current_produceable > produceable' do
      before do
        component.update(can_be_produced: 50)
        part.can_be_produced = 4
        part.available_count = 5
      end

      it 'lowers the can_be_produced value to produceable' do
        expect { job.calculate_for_combination(assembly) }
          .to change { component.reload.can_be_produced }
          .from(50).to(4)
      end
    end
  end

  describe '#loop_parts' do
    let(:material) { create :material }
    let(:parts) { create_list :part_from_material, 3, material: }

    it 'passes each part to update_part' do
      parts
      expect(job).to receive(:update_part).exactly(3).times

      job.loop_parts(material)
    end
  end

  describe '#update_part' do
    let(:part) { create :part, quantity_from_material: 10 }
    let(:material_available_count) { 3 }

    it 'updates a part' do
      expect(part).to receive(:update_columns).with(can_be_produced: 30)

      job.update_part(part, material_available_count)
    end
  end
end
