# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GoalRemainderCalculationJob, type: :job do
  let(:job) { GoalRemainderCalculationJob.new }

  it 'queues as goal_remainder' do
    expect(job.queue_name).to eq 'goal_remainder'
  end

  describe '#perform' do
    it 'calls set_all_item_goal_remainders_to_zero' do
      expect(job).to receive(:set_all_item_goal_remainders_to_zero)

      job.perform
    end

    context 'when a technology\'s goal is 0' do
      let(:technology_no_goal) { create :technology, default_goal: 0 }

      it 'does nothing to that technology' do
        expect(technology_no_goal).not_to receive(:default_goal)

        expect(job).not_to receive(:loop_assemblies).with(technology_no_goal, anything)

        job.perform
      end
    end

    context 'for each technology with a goal' do
      context 'and a positive remainder' do
        let(:technology_w_remainder) { create :technology, default_goal: 20, available_count: 12 }

        it 'calls loop_assemblies' do
          expect(job).to receive(:loop_assemblies).with(technology_w_remainder, 8)

          job.perform
        end
      end

      context 'and a non-positive remainder' do
        let(:technology_no_remainder) { create :technology, default_goal: 20, available_count: 22 }

        it 'does not call loop_assemblies' do
          expect(job).not_to receive(:loop_assemblies).with(technology_no_remainder, anything)
        end
      end
    end
  end

  describe '#loop_assemblies' do
    let(:combination) { create :technology, default_goal: 20, available_count: 8 }

    context 'when the new remainder is not positive' do
      let(:assemblies) { create_list :assembly_tech, 2, combination: combination, item: create(:component, available_count: 900) }

      it 'doesn\'t call set_item_goal_remainder' do
        assemblies

        expect(job).not_to receive(:set_item_goal_remainder)

        job.loop_assemblies(combination, 12)
      end
    end

    context 'when the new remainder is positive' do
      let(:assemblies) { create_list :assembly_tech, 2, combination: combination, item: create(:component, available_count: 2) }

      it 'calls set_item_goal_remainder' do
        assemblies

        expect(job).to receive(:set_item_goal_remainder).exactly(2).times

        job.loop_assemblies(combination, 12)
      end
    end

    context 'when the item is a Component and has sub-assemblies' do
      let(:component) { create :component }
      let(:assembly) { create :assembly_tech, combination: combination, item: component }
      let(:sub_assembly) { create :assembly, combination: component }

      it 'calls loop_components with the item' do
        assembly
        sub_assembly

        allow(job).to receive(:loop_assemblies).with(combination, 12).and_call_original

        expect(job).to receive(:loop_assemblies).with(component, anything)

        job.loop_assemblies(combination, 12)
      end
    end

    context 'when the item is a Part and is made from a material' do
      let(:part) { create :part_from_material }
      let(:assembly) { create :assembly_tech, combination: combination, item: part }

      it 'calls set_material_goal_remainder' do
        assembly

        expect(job).to receive(:set_material_goal_remainder).with(part, anything)

        job.loop_assemblies(combination, 12)
      end
    end
  end

  describe '#set_all_item_goal_remainders_to_zero' do
    let(:component) { create :component, goal_remainder: 10 }
    let(:part) { create :part, goal_remainder: 8 }
    let(:material) { create :material, goal_remainder: 6 }

    it 'sets all Components goal_remainders to zero' do
      expect { job.set_all_item_goal_remainders_to_zero }
        .to change { component.reload.goal_remainder }
        .from(10).to(0)
    end

    it 'sets all Parts goal_remainders to zero' do
      expect { job.set_all_item_goal_remainders_to_zero }
        .to change { part.reload.goal_remainder }
        .from(8).to(0)
    end

    it 'sets all Materials goal_remainders to zero' do
      expect { job.set_all_item_goal_remainders_to_zero }
        .to change { material.reload.goal_remainder }
        .from(6).to(0)
    end
  end

  describe '#set_item_goal_remainder' do
    let(:item) { create :component, goal_remainder: 12 }

    it 'sets the item\'s goal_remainder to a new value' do
      expect { job.set_item_goal_remainder(item, 4) }
        .to change { item.reload.goal_remainder }
        .from(12).to(16)
    end
  end

  describe '#set_material_goal_remainder' do
    let(:material) { create :material, goal_remainder: 1, available_count: 1 }
    let(:part) { create :part_from_material, material: material, quantity_from_material: 2.5 }

    it 'sets the material\'s goal_remainder to a new value' do
      expect { job.set_material_goal_remainder(part, 6) }
        .to change { material.reload.goal_remainder }
        .from(1).to(4)
    end
  end
end
