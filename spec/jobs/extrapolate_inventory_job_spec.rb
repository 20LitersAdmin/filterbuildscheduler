# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventInventoryJob, type: :job do
  before :all do
    @tech1 = create :technology, name: 'Tech1', loose_count: 10, box_count: 2, quantity_per_box: 20
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

    @tech_a = create :technology, name: 'Tech_a', loose_count: 5, box_count: 5, quantity_per_box: 10
    @part_a = create :part, name: 'Part_a', loose_count: 200, box_count: 5, quantity_per_box: 100
    Assembly.create(combination: @tech_a, item: @part_a, quantity: 1)
    @part_b = create :part, name: 'Part_b', loose_count: 20, box_count: 2, quantity_per_box: 10
    Assembly.create(combination: @tech_a, item: @part_b, quantity: 1)
    @mat_a = create :material, name: 'Mat_a', supplier: nil, quantity_per_box: 200, loose_count: 4
    @part_c = create :part_from_material, name: 'Part_c', loose_count: 2, box_count: 0, quantity_per_box: 300, material: @mat_a
    Assembly.create(combination: @tech_a, item: @part_c, quantity: 1)

    QuantityAndDepthCalculationJob.perform_now

    @inventory = Inventory.create(extrapolate: true, technologies: Technology.all.pluck(:id), date: Date.today)
    CountCreateJob.perform_now(@inventory)

    @job = ExtrapolateInventoryJob.new(@inventory)
  end

  it 'queues as extrapolate_inventory' do
    expect(@job.queue_name).to eq 'extrapolate_inventory'
  end

  context 'when a number of technologies were boxed up' do
    pending
  end

  context 'when a number of technologies were created from child items' do
    pending
  end

  context 'when technologies and components were created from child items' do
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
