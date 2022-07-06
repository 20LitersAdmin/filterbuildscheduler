# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventInventoryJob, type: :job do
  include ActiveJob::TestHelper

  before :all do
    @tech1 = create :technology, name: 'Tech1', loose_count: 100, box_count: 2, quantity_per_box: 20
    @comp1 = create :component, name: 'Comp1', loose_count: 4, box_count: 8, quantity_per_box: 5
    Assembly.create(combination: @tech1, item: @comp1, quantity: 1)
    @mat1 = create :material, name: 'Mat1', supplier: nil, quantity_per_box: 200, loose_count: 2, box_count: 3
    @part1 = create :part_from_material, material: @mat1, name: 'Part1', loose_count: 200, box_count: 0, quantity_per_box: 0, quantity_from_material: 10
    Assembly.create(combination: @comp1, item: @part1, quantity: 2)
    @part2 = create :part, name: 'Part2', loose_count: 200, box_count: 5, quantity_per_box: 100
    Assembly.create(combination: @comp1, item: @part2, quantity: 2)

    @comp2 = create :component, name: 'Comp2', loose_count: 8, box_count: 1, quantity_per_box: 200
    Assembly.create(combination: @tech1, item: @comp2, quantity: 2)
    @mat2 = create :material, name: 'Mat2', supplier: nil, quantity_per_box: 200, loose_count: 4
    @part3 = create :part_from_material, material: @mat2, name: 'Part3', loose_count: 200, box_count: 0, quantity_per_box: 0, quantity_from_material: 6
    Assembly.create(combination: @comp2, item: @part3, quantity: 2)
    @part4 = create :part, name: 'Part4', loose_count: 200, box_count: 5, quantity_per_box: 100
    Assembly.create(combination: @comp2, item: @part4, quantity: 2)
    @part5 = create :part, name: 'Part5', loose_count: 90, box_count: 5, quantity_per_box: 50
    Assembly.create(combination: @tech1, item: @part5, quantity: 1)

    @tech_a = create :technology, name: 'Tech_a', loose_count: 40, box_count: 5, quantity_per_box: 10
    @part_a = create :part, name: 'Part_a', loose_count: 200, box_count: 5, quantity_per_box: 100
    Assembly.create(combination: @tech_a, item: @part_a, quantity: 1)
    @part_b = create :part, name: 'Part_b', loose_count: 20, box_count: 2, quantity_per_box: 10
    Assembly.create(combination: @tech_a, item: @part_b, quantity: 1)
    @mat_a = create :material, name: 'Mat_a', supplier: nil, quantity_per_box: 200, loose_count: 4
    @part_c = create :part_from_material, name: 'Part_c', loose_count: 2, box_count: 0, quantity_per_box: 300, material: @mat_a
    Assembly.create(combination: @tech_a, item: @part_c, quantity: 1)

    QuantityAndDepthCalculationJob.perform_now

    @inventory = Inventory.create(extrapolate: true, technologies: Technology.all.pluck(:id), date: Date.today, completed_at: Date.today)
    CountCreateJob.perform_now(@inventory)

    @job = ExtrapolateInventoryJob.new(@inventory)
  end

  it 'queues as extrapolate_inventory' do
    expect(@job.queue_name).to eq 'extrapolate_inventory'
  end

  context 'when the number of technologies boxed up can be satisfied by the number of loose technologies' do
    before :all do
      @tech1_count = @inventory.counts.where(item: @tech1).first
      @tech1_count.update(unopened_boxes_count: 1)

      @tech_a_count = @inventory.counts.where(item: @tech_a).first
      @tech_a_count.update(unopened_boxes_count: 2)
    end

    it 'updates the Technology to subtract from loose and add to boxes' do
      perform_enqueued_jobs do
        expect { @job.perform_now }
          .to change { @tech1.reload.loose_count }
          .from(100).to(80)
          .and change { @tech1.reload.box_count }
          .from(2).to(3)
          .and change { @tech_a.reload.loose_count }
          .from(40).to(20)
          .and change { @tech_a.reload.box_count }
          .from(5).to(7)
      end
    end
  end

  context 'when a number of technologies were created from child items' do
    before :all do
      @tech1_count = @inventory.counts.where(item: @tech1).first
      # @tech1: loose_count: 100, box_count: 2, q_per_box: 20
      # @tech1_count: produced_and_boxed: 140, produced_total: 148
      # remainder: 40
      @tech1_count.update(unopened_boxes_count: 7, loose_count: 8)

      # @tech_a: loose_count: 40, box_count: 5, q_per_box: 10
      @tech_a_count = @inventory.counts.where(item: @tech_a).first
      # produced_and_boxed: 50, total_produced: 57
      # remainder: 10
      @tech_a_count.update(unopened_boxes_count: 5, loose_count: 7)
    end

    fit 'updates related Item\'s loose and box counts as necessary to satisfy the number of items produced' do
      # expect(@job).to receive(:item_can_satisfy_remainder).with(@comp1, 40)

      # perform_enqueued_jobs do
      #   expect { @job.perform_now }
      #     .to change { @tech1.reload.loose_count }
      #     .from(100).to(8)
      #     .and change { @tech1.reload.box_count }
      #     .from(2).to(9)
      #     .and change { @comp1.reload.box_count }
      #     .from(8).to(0)
      #     .and not_change { @comp1.reload.loose_count }
      #     .from(4)
      #     .and change { @tech_a.reload.loose_count }
      #     .from(40).to(7)
      #     .and change { @tech_a.reload.box_count }
      #     .from(5).to(10)
      # end
    end
  end

  context 'when technologies *and* components were created from child items' do
    pending
  end

  context 'when the created technologies and components will zero out one or more child items' do
    pending
  end

  context 'when the created technologies and components involves child item boxes being opened' do
    pending
  end

  context 'when the created technologies and components involves materials being turned into parts' do
    pending
  end
end
