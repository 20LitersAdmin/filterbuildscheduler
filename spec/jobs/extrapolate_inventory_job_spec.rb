# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventInventoryJob, type: :job do
  include ActiveJob::TestHelper

  before do
    @tech1 = create :technology, name: 'Tech1', loose_count: 100, box_count: 2, quantity_per_box: 20
    @comp1 = create :component, name: 'Comp1', loose_count: 4, box_count: 8, quantity_per_box: 5
    Assembly.create(combination: @tech1, item: @comp1, quantity: 1)
    @mat1 = create :material, name: 'Mat1', supplier: nil, quantity_per_box: 200, loose_count: 2, box_count: 3
    @part1 = create :part_from_material, material: @mat1, name: 'Part1', loose_count: 200, box_count: 0, quantity_per_box: 0, quantity_from_material: 10
    Assembly.create(combination: @comp1, item: @part1, quantity: 2)
    @part2 = create :part, name: 'Part2', loose_count: 200, box_count: 5, quantity_per_box: 100
    Assembly.create(combination: @comp1, item: @part2, quantity: 4)

    @comp2 = create :component, name: 'Comp2', loose_count: 8, box_count: 1, quantity_per_box: 200
    Assembly.create(combination: @tech1, item: @comp2, quantity: 2)
    @mat2 = create :material, name: 'Mat2', supplier: nil, loose_count: 4, box_count: 1, quantity_per_box: 200
    @part3 = create :part_from_material, material: @mat2, name: 'Part3', loose_count: 224, box_count: 0, quantity_per_box: 0, quantity_from_material: 6
    Assembly.create(combination: @comp2, item: @part3, quantity: 2)
    @part4 = create :part, name: 'Part4', loose_count: 16, box_count: 5, quantity_per_box: 100
    Assembly.create(combination: @comp2, item: @part4, quantity: 2)
    @part5 = create :part, name: 'Part5', loose_count: 90, box_count: 5, quantity_per_box: 50
    Assembly.create(combination: @tech1, item: @part5, quantity: 1)

    @tech_a = create :technology, name: 'Tech_a', loose_count: 40, box_count: 5, quantity_per_box: 10
    @part_a = create :part, name: 'Part_a', loose_count: 200, box_count: 5, quantity_per_box: 100
    Assembly.create(combination: @tech_a, item: @part_a, quantity: 3)
    @part_b = create :part, name: 'Part_b', loose_count: 4, box_count: 1, quantity_per_box: 2
    Assembly.create(combination: @tech_a, item: @part_b, quantity: 1)
    @mat_a = create :material, name: 'Mat_a', supplier: nil, loose_count: 4
    @part_c = create :part_from_material, name: 'Part_c', loose_count: 2, box_count: 0, quantity_per_box: 300, material: @mat_a, quantity_from_material: 24
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
    before do
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
    before do
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

    it 'updates related Item\'s loose and box counts as necessary to satisfy the number of items produced' do
      perform_enqueued_jobs do
        expect { @job.perform_now }
          .to change { @tech1.reload.loose_count }
          .from(100).to(8)
          .and change { @tech1.reload.box_count }
          .from(2).to(9)
          .and change { @comp1.reload.box_count }
          .from(8).to(0)
          .and not_change { @comp1.reload.loose_count }
          .from(4)
          .and not_change { @mat1.reload.available_count }
          .from(602)
          .and not_change { @part1.reload.available_count }
          .from(200)
          .and not_change { @part2.reload.available_count }
          .from(700)
          .and change { @comp2.reload.box_count }
          .from(1).to(0)
          .and change { @comp2.reload.loose_count }
          .from(8).to(128)
          .and not_change { @mat2.reload.available_count }
          .from(204)
          .and not_change { @part3.reload.available_count }
          .from(224)
          .and not_change { @part4.reload.available_count }
          .from(516)
          .and change { @part5.reload.loose_count }
          .from(90).to(50)
          .and not_change { @part5.reload.box_count }
          .from(5)
          .and change { @tech_a.reload.loose_count }
          .from(40).to(7)
          .and change { @tech_a.reload.box_count }
          .from(5).to(10)
          .and change { @part_a.reload.loose_count }
          .from(200).to(170)
          .and not_change { @part_a.reload.box_count }
          .from(5)
          .and change { @part_b.reload.available_count }
          .from(6).to(0)
          .and change { @part_c.reload.loose_count }
          .from(2).to(16)
          .and not_change { @part_c.reload.box_count }
          .from(0)
          .and change { @mat_a.reload.loose_count }
          .from(4).to(3)
          .and not_change { @mat_a.reload.box_count }
          .from(0)
      end
    end
  end

  context 'when technologies *and* components were created from child items' do
    before do
      @tech1_count = @inventory.counts.where(item: @tech1).first
      # @tech1: loose_count: 100, box_count: 2, q_per_box: 20
      # @tech1_count: produced_and_boxed: 140, produced_total: 148
      # remainder: 40
      @tech1_count.update(unopened_boxes_count: 7, loose_count: 8)

      @comp1_count = @inventory.counts.where(item: @comp1).first
      # @comp1: loose_count: 4, box_count: 8, q_per_box: 5
      @comp1_count.update(unopened_boxes_count: 2, loose_count: 3)
      # @comp1_count: produced_and_boxed: 10, produced_total: 13
      # remainder: 6

      @comp2_count = @inventory.counts.where(item: @comp2).first
      # @comp2: loose_count: 8, box_count: 1, q_per_box: 200
      @comp2_count.update(loose_count: 143, unopened_boxes_count: 1)
      # @comp2_count: produced_and_boxed: 200, produced_total: 343
      # remainder: 94
    end

    it 'updates related Item\'s loose and box counts as necessary to satisfy the number of items produced' do
      perform_enqueued_jobs do
        expect { @job.perform_now }
          .to change { @tech1.reload.loose_count }
          .from(100).to(8)
          .and change { @tech1.reload.box_count }
          .from(2).to(9)
          .and change { @comp1.reload.box_count }
          .from(8).to(2)
          .and change { @comp1.reload.loose_count }
          .from(4).to(7)
          .and not_change { @mat1.reload.available_count }
          .from(602)
          .and change { @part1.reload.loose_count }
          .from(200).to(188)
          .and change { @part2.reload.loose_count }
          .from(200).to(176)
          .and not_change { @comp2.reload.box_count }
          .from(1)
          .and change { @comp2.reload.loose_count }
          .from(8).to(271)
          .and change { @part3.reload.loose_count }
          .from(224).to(2)
          .and not_change { @part3.reload.box_count }
          .from(0)
          .and change { @mat2.reload.loose_count }
          .from(4).to(177)
          .and change { @mat2.reload.box_count }
          .from(1).to(0)
          .and change { @part4.reload.box_count }
          .from(5).to(1)
          .and change { @part4.reload.loose_count }
          .from(16).to(32)
          .and change { @part5.reload.loose_count }
          .from(90).to(50)
          .and not_change { @part5.reload.box_count }
          .from(5)
      end
    end
  end
end
