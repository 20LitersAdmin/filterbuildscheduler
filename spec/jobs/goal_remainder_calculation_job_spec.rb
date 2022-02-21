# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GoalRemainderCalculationJob, type: :job do
  let(:job) { GoalRemainderCalculationJob.new }

  it 'queues as goal_remainder' do
    expect(job.queue_name).to eq 'goal_remainder'
  end

  describe '#perform' do
    it 'sets every active Item\'s goal remainder to 0' do
      allow(Component).to receive_message_chain(:kept, :each).and_return(instance_double(Component))
      allow(Part).to receive_message_chain(:kept, :each).and_return(instance_double(Part))
      allow(Material).to receive_message_chain(:kept, :each).and_return(instance_double(Material))
      allow(Part).to receive_message_chain(:made_from_material, :each).and_return(instance_double(Part))

      expect(Component).to receive_message_chain(:kept, :update_all).with(goal_remainder: 0)

      expect(Part).to receive_message_chain(:kept, :update_all).with(goal_remainder: 0)

      expect(Material).to receive_message_chain(:kept, :update_all).with(goal_remainder: 0)

      job.perform
    end

    it 'loops over technologies with set goals' do
      techs = create_list(:technology, 3)
      tech_w_no_goal = create(:technology, default_goal: 0)

      expect(Technology).to receive(:with_set_goal).and_call_original

      techs.each do |tech|
        expect(job).to receive(:increase_goal_remainders_for_all_items).with(tech)
      end

      expect(job).not_to receive(:increase_goal_remainders_for_all_items).with(tech_w_no_goal)

      job.perform
    end

    it 'loops over all assemblies' do
      expect(Assembly).to receive_message_chain(:all, :each)

      job.perform
    end

    it 'loops over parts made from a material' do
      expect(Part).to receive_message_chain(:made_from_material, :each)

      job.perform
    end

    it 'loops over every Item class' do
      allow(Component).to receive_message_chain(:kept, :update_all)
      allow(Part).to receive_message_chain(:kept, :update_all)
      allow(Material).to receive_message_chain(:kept, :update_all)
      allow(Part).to receive_message_chain(:made_from_material, :each)

      expect(Component.kept).to receive(:each).once
      expect(Part.kept).to receive(:each).once
      expect(Material.kept).to receive(:each).once

      job.perform
    end
  end

  describe '#increase_goal_remainders_for_all_items' do
    it 'adds to an item\'s existing goal_remainder' do
      assembly = create(:assembly_tech_part, quantity: 2)
      tech = assembly.combination
      tech.update_columns(goal_remainder: 42)
      part = assembly.item
      tech.quantities[part.uid] = 2
      tech.save

      expect { job.increase_goal_remainders_for_all_items(tech) }
        .to change { part.reload.goal_remainder }
        .from(0).to(84)
    end
  end

  describe 'subtract_combination_available_count_from_item_goal_remainder' do
    it 'subtracts a combination\'s available_count from an item\'s goal remainder' do
      assembly = create(:assembly_tech_part, quantity: 2)
      tech = assembly.combination
      tech.update_columns(goal_remainder: 32, available_count: 10)
      part = assembly.item
      part.update_columns(goal_remainder: 44)

      expect { job.subtract_combination_available_count_from_item_goal_remainder(assembly) }
        .to change { part.goal_remainder }
        .from(44).to(24)
    end
  end

  describe 'subtract_item_available_count' do
    it 'lowers an item\'s goal_remainder by it\'s available count' do
      item = create(:part, goal_remainder: 36, available_count: 10)

      expect { job.subtract_item_available_count(item) }
        .to change { item.goal_remainder }
        .from(36).to(26)
    end
  end

  describe 'subtract_part_available_count_from_material_goal_remainder' do
    it "subtracts a part's available count from the material's goal remainder" do
      material = create(:material, goal_remainder: 25)
      part = create(:part_from_material, material: material, available_count: 75)

      expect { job.subtract_part_available_count_from_material_goal_remainder(part) }
        .to change { material.goal_remainder }
        .from(25).to(10)
    end
  end
end
