# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GoalRemainderCalculationJob, type: :job do
  let(:job) { GoalRemainderCalculationJob.new }

  it 'queues as goal_remainder' do
    expect(job.queue_name).to eq 'goal_remainder'
  end

  describe '#perform' do
    context 'when called with a technology' do
      let(:technology) { create :technology }

      it 'calls set_all_tech_items_goal_remainders_to_zero' do
        expect(job).to receive(:set_all_tech_items_goal_remainders_to_zero).with(technology)

        job.perform(technology)
      end

      it 'calls process_technology with the given technology' do
        expect(job).to receive(:process_technology).with(technology)

        job.perform(technology)
      end
    end

    context 'when called without a technology' do
      it 'calls set_all_item_goal_remainders_to_zero' do
        expect(job).to receive(:set_all_item_goal_remainders_to_zero)

        job.perform
      end

      context 'for any technology without a set goal' do
        let(:technology) { create :technology, default_goal: 0 }

        it 'does nothing' do
          technology

          expect(job).not_to receive(:process_technology).with(technology)

          job.perform
        end
      end

      context 'for each technology with a set goal' do
        let(:technologies) { create_list :technology, 3, default_goal: Random.rand(40..140) }

        it 'calls process_technology with that technology' do
          technologies.each do |tech|
            expect(job).to receive(:process_technology).with(tech)
          end

          job.perform
        end
      end
    end
  end

  describe '#process_assembly' do
    let(:item) { create :part, goal_remainder: 100 }
    let(:assembly) { create :assembly, item: item, quantity: 2 }

    context 'when the new_goal_remainder is positive' do
      it 'sets the item\'s goal_remainder to new_goal_remainder' do
        expect { job.process_assembly(assembly, 30) }
          .to change { item.reload.goal_remainder }
          .from(100).to(40)
      end
    end

    context 'when the new_goal_remainder is negative' do
      it 'sets the item\'s goal_remainder to 0' do
        expect { job.process_assembly(assembly, 55) }
          .to change { item.reload.goal_remainder }
          .from(100).to(0)
      end
    end

    context 'when the item is a Part made from a material' do
      let(:material) { create :material, goal_remainder: 8 }
      let(:part) { create :part_from_material, material: material, quantity_from_material: 5, available_count: 12, goal_remainder: 10 }
      let(:part_assembly) { create :assembly, item: part, quantity: 1 }

      context 'when the material_new_goal_remainder is positive' do
        it 'sets the material\'s goal_remainder to material_new_goal_remainder' do
          # in_parent_available = 20 * 1
          # material_in_parent_available = (12 + 20) / 5
          # material_new_goal_remainder = 8 - 6
          expect { job.process_assembly(part_assembly, 20) }
            .to change { material.reload.goal_remainder }
            .from(8).to(2)
        end
      end

      context 'when the material_new_goal_remainder is negative' do
        it 'sets the material\'s goal_remainder to 0' do
          expect { job.process_assembly(part_assembly, 90) }
            .to change { material.reload.goal_remainder }
            .from(8).to(0)
        end
      end
    end

    context 'when the item is a Component and has sub-assemblies' do
      let(:component) { create :component, goal_remainder: 40 }
      let(:comp_assembly) { create :assembly, item: component, quantity: 1 }
      let(:comp_sub_assemblies) { create_list :assembly, 3, combination: component }

      it 'calls process_assembly for each sub assembly' do
        allow(job).to receive(:process_assembly).with(comp_assembly, anything).and_call_original

        comp_sub_assemblies.each do |asbly|
          expect(job).to receive(:process_assembly).with(asbly, anything)
        end

        job.process_assembly(comp_assembly, 14)
      end
    end
  end

  describe '#process_technology' do
    context 'when a technology\'s goal is less than or equal to it\'s available_count' do
      let(:technology_no_goal) { create :technology, default_goal: 0, available_count: 1 }
      let(:assembly) { create :assembly, combination: technology_no_goal }

      it 'does nothing to that technology' do
        expect(technology_no_goal).not_to receive(:quantities)

        expect(job).not_to receive(:process_assembly).with(assembly, anything)

        job.process_technology(technology_no_goal)
      end
    end

    context 'when a technology\'s goal is greater than it\'s available_count' do
      let(:technology) { create :technology, default_goal: 30, available_count: 20 }
      let(:assemblies) { create_list :assembly_tech, 3, combination: technology, quantity: 1 }

      it 'sets item\'s goal_remainder to the max value possible' do
        # build technology.quantities
        assemblies.each do |asbly|
          technology.quantities[asbly.item.uid] = asbly.quantity
        end
        technology.save

        # stub out the loop of tech.assemblies.without_price_only
        # so process_assembly doesn't morph
        allow(job).to receive(:process_assembly).and_return(true)

        job.process_technology(technology)

        assemblies.each do |asbly|
          expect(asbly.item.reload.goal_remainder).to eq 30
        end
      end

      it 'calls process_assembly on each assembly' do
        # build technology.quantities
        assemblies.each do |asbly|
          technology.quantities[asbly.item.uid] = asbly.quantity
        end
        technology.save

        assemblies.each do |asbly|
          expect(job).to receive(:process_assembly).with(asbly, 0)
        end

        job.process_technology(technology)
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

  describe '#set_all_tech_items_goal_remainders_to_zero' do
    let(:technology) { create :technology, default_goal: 30, available_count: 20 }
    let(:assemblies) { create_list :assembly_tech, 3, combination: technology, quantity: 1 }

    context 'for items related to the given technology' do
      it 'sets the goal_remainder to 0' do
        # build technology.quantities
        assemblies.each do |asbly|
          technology.quantities[asbly.item.uid] = asbly.quantity
          asbly.item.update_columns(goal_remainder: 20)
        end
        technology.save

        expect { job.set_all_tech_items_goal_remainders_to_zero(technology) }
          .to change { Component.all.pluck(:goal_remainder) }
          .from([20, 20, 20]).to([0, 0, 0])
      end
    end

    context 'for items unrelated to the given technology' do
      let(:component) { create :component, goal_remainder: 45 }

      it 'doesn\'t change their goal_remainders' do
        # build technology.quantities
        assemblies.each do |asbly|
          technology.quantities[asbly.item.uid] = asbly.quantity
          asbly.item.update_columns(goal_remainder: 20)
        end
        technology.save

        expect { job.set_all_tech_items_goal_remainders_to_zero(technology) }
          .not_to change { component.goal_remainder }
      end
    end
  end
end
