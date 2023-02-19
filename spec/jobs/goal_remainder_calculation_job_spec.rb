# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GoalRemainderCalculationJob, type: :job do
  let(:job) { GoalRemainderCalculationJob.new }

  it 'queues as goal_remainder' do
    expect(job.queue_name).to eq 'goal_remainder'
  end

  describe 'RESULTS TEST' do
      # Mock up a real structure
      let(:sam3) { create :technology, available_count: 1470, default_goal: 2480 }
      # first layer: outflow loop, cartridge w faucet
      let(:outflow) { create :component, available_count: 239, name: 'outflow' }
      let(:asbly_sam3_outflow) { create :assembly, combination: sam3, item: outflow, quantity: 1 }
      let(:cartridge) { create :component, available_count: 283, name: 'cartridge' }
      let(:asbly_sam3_cartridge) { create :assembly, combination: sam3, item: cartridge, quantity: 1 }
      # second layer of outflow loop:
      let(:blue) { create :component, available_count: 38, name: 'blue' }
      let(:asbly_outflow_blue) { create :assembly, combination: outflow, item: blue, quantity: 1 }
      let(:red) { create :component, available_count: 40, name: 'red' }
      let(:asbly_outflow_red) { create :assembly, combination: outflow, item: red, quantity: 1 }
      let(:pipe) { create :material, available_count: 1, name: 'pipe' }
      let(:green) { create :part, available_count: 160, material: pipe, made_from_material: true, quantity_from_material: 45, name: 'green' }
      let(:asbly_outflow_green) { create :assembly, combination: outflow, item: green, quantity: 1 }
      # third layer of outflow loop: blue
      let(:cap_w_screen) { create :component, available_count: 418, name: 'cap_w_screen' }
      let(:asbly_blue_cap_w_screen) { create :assembly, combination: blue, item: cap_w_screen, quantity: 1 }
      let(:blue_pipe) { create :part, available_count: 121, material: pipe, made_from_material: true, quantity_from_material: 36, name: 'blue_pipe' }
      let(:asbly_blue_blue_pipe) { create :assembly, combination: blue, item: blue_pipe, quantity: 1 }
      let(:elbow) { create :part, available_count: 118, name: 'elbow' }
      let(:asbly_blue_elbow) { create :assembly, combination: blue, item: elbow, quantity: 1 }
      # third layer of outflow loop: red
      let(:bulkhead) { create :component, available_count: 166, name: 'bulkhead' }
      let(:asbly_red_bulkhead) { create :assembly, combination: red, item: bulkhead, quantity: 1 }
      let(:red_pipe) { create :part, available_count: 97, material: pipe, made_from_material: true, quantity_from_material: 32, name: 'red_pipe' }
      let(:asbly_red_red_pipe) { create :assembly, combination: red, item: red_pipe, quantity: 1 }
      let(:asbly_red_elbow) { create :assembly, combination: red, item: elbow, quantity: 1 }
      # fourth & fifth layer of outflow loop: cap_w_screen
      let(:undrilled_cap) { create :material, available_count: 0, name: 'undrilled_cap' }
      let(:cap) { create :part, available_count: 516, material: undrilled_cap, quantity_from_material: 1, made_from_material: true, name: 'cap' }
      let(:asbly_cap_w_screen_cap) { create :assembly, combination: cap_w_screen, item: cap, quantity: 1 }
      let(:screen) { create :part, available_count: 7110, name: 'screen' }
      let(:asbly_cap_w_screen_screen) { create :assembly, combination: cap_w_screen, item: screen, quantity: 1 }
      # fourth & fifth layer of outflow loop: bulkhead
      let(:beveled_washer) { create :part, available_count: 1624, name: 'beveled_washer' }
      let(:asbly_bulkhead_beveled_washer) { create :assembly, combination: bulkhead, item: beveled_washer, quantity: 1 }
      let(:male_adapter) { create :part, available_count: 61, name: 'male_adapter' }
      let(:asbly_bulkhead_male_adapter) { create :assembly, combination: bulkhead, item: male_adapter, quantity: 1 }
      let(:locknut) { create :part, available_count: 647, name: 'locknut' }
      let(:asbly_bulkhead_locknut) { create :assembly, combination: bulkhead, item: locknut, quantity: 1 }
      let(:black_washer) { create :part, available_count: 6256, name: 'black_washer' }
      let(:asbly_bulkhead_black_washer) { create :assembly, combination: bulkhead, item: black_washer, quantity: 1 }

      # second layer of cartridge w faucet
      let(:cartridge_assembled) { create :component, available_count: 608, name: 'cartridge_assembled' }
      let(:asbly_cartridge_cartridge_assembled) { create :assembly, combination: cartridge, item: cartridge_assembled, quantity: 1 }
      let(:faucet_w_washers) { create :component, available_count: 0, name: 'faucet_w_washers' }
      let(:asbly_catridge_faucet_w_washers) { create :assembly, combination: cartridge, item: faucet_w_washers, quantity: 1 }
      let(:faucet_adapter) { create :part, available_count: 496, name: 'faucet_adapter' }
      let(:asbly_catridge_faucet_adapter) { create :assembly, combination: cartridge, item: faucet_adapter, quantity: 1 }
      # third layer of cartridge w faucet: cartridge assembled
      let(:membrane_w_both) { create :component, available_count: 0, name: 'membrane_w_both' }
      let(:asbly_catridge_assembled_membrane_w_both) { create :assembly, combination: cartridge_assembled, item: membrane_w_both, quantity: 1 }
      let(:body_w_ring) { create :component, available_count: 32, name: 'body_w_ring' }
      let(:asbly_cartridge_assembled_body_w_ring) { create :assembly, combination: cartridge_assembled, item: body_w_ring, quantity: 1 }
      let(:head) { create :part, available_count: 52, name: 'head' }
      let(:asbly_cartridge_assembled_head) { create :assembly, combination: cartridge_assembled, item: head, quantity: 1 }
      # fourth layer of cartridge w faucet: body w ring
      let(:body) { create :part, available_count: 0, name: 'body' }
      let(:asbly_body_w_ring_body) { create :assembly, combination: body_w_ring, item: body, quantity: 1 }
      let(:body_o_ring) { create :part, available_count: 71, name: 'body_o_ring' }
      let(:asbly_body_w_ring_body_o_ring) { create :assembly, combination: body_w_ring, item: body_o_ring, quantity: 1 }
      # fourth layer of cartridge w faucet: membrane w both
      let(:membrane_w_thick) { create :component, available_count: 32, name: 'membrane_w_thick' }
      let(:asbly_membrane_w_both_membrane_w_thick) { create :assembly, combination: membrane_w_both, item: membrane_w_thick, quantity: 1 }
      let(:thin_o_ring) { create :part, available_count: 0, name: 'thin_o_ring' }
      let(:asbly_membrane_w_both_thin_o_ring) { create :assembly, combination: membrane_w_both, item: thin_o_ring, quantity: 1 }
      # fifth layer of cartridge w faucet: membrane_w_thick
      let(:membrane) { create :part, available_count: 0, name: 'membrane' }
      let(:asbly_membrane_w_thick_membrane) { create :assembly, combination: membrane_w_thick, item: membrane, quantity: 1 }
      let(:thick_o_ring) { create :part, available_count: 18, name: 'thick_o_ring' }
      let(:asbly_membrane_w_thick_thick_o_ring) { create :assembly, combination: membrane_w_thick, item: thick_o_ring, quantity: 1 }
      # third layer of catridge w faucet: faucet w washers
      let(:asbly_faucet_w_washers_beveled_washer) { create :assembly, combination: faucet_w_washers, item: beveled_washer, quantity: 1 }
      let(:asbly_faucet_w_washers_black_washer) { create :assembly, combination: faucet_w_washers, item: black_washer, quantity: 1 }
      let(:faucet) { create :part, available_count: 8119, name: 'faucet' }
      let(:asbly_faucet_w_washers_faucet) { create :assembly, combination: faucet_w_washers, item: faucet, quantity: 1 }

      before do
        # save the headache of having to set loose_count, box_count and quantity_per_box on all items
        allow_any_instance_of(Technology).to receive(:update_available_count).and_return true
        allow_any_instance_of(Component).to receive(:update_available_count).and_return true
        allow_any_instance_of(Part).to receive(:update_available_count).and_return true
        allow_any_instance_of(Material).to receive(:update_available_count).and_return true

        # touch all the assemblies to make them persist
        # level ones
        asbly_sam3_outflow
        asbly_sam3_cartridge
        asbly_outflow_blue
        asbly_outflow_red
        asbly_outflow_green
        asbly_blue_cap_w_screen
        asbly_blue_blue_pipe
        asbly_blue_elbow
        asbly_red_bulkhead
        asbly_red_red_pipe
        asbly_red_elbow
        asbly_cap_w_screen_cap
        asbly_cap_w_screen_screen
        asbly_bulkhead_beveled_washer
        asbly_bulkhead_male_adapter
        asbly_bulkhead_locknut
        asbly_bulkhead_black_washer
        asbly_cartridge_cartridge_assembled
        asbly_catridge_faucet_w_washers
        asbly_catridge_faucet_adapter
        asbly_catridge_assembled_membrane_w_both
        asbly_cartridge_assembled_body_w_ring
        asbly_cartridge_assembled_head
        asbly_body_w_ring_body
        asbly_body_w_ring_body_o_ring
        asbly_membrane_w_both_membrane_w_thick
        asbly_membrane_w_both_thin_o_ring
        asbly_membrane_w_thick_membrane
        asbly_membrane_w_thick_thick_o_ring
        asbly_faucet_w_washers_beveled_washer
        asbly_faucet_w_washers_black_washer
        asbly_faucet_w_washers_faucet

        QuantityAndDepthCalculationJob.perform_now
      end

      it 'calculates goal_remainder for all items' do
        expect(sam3.goal_remainder).to eq 0
        expect(outflow.goal_remainder).to eq 0
        expect(cartridge.goal_remainder).to eq 0
        expect(blue.goal_remainder).to eq 0
        expect(red.goal_remainder).to eq 0
        expect(pipe.goal_remainder).to eq 0
        expect(green.goal_remainder).to eq 0
        expect(cap_w_screen.goal_remainder).to eq 0
        expect(blue_pipe.goal_remainder).to eq 0
        expect(elbow.goal_remainder).to eq 0
        expect(bulkhead.goal_remainder).to eq 0
        expect(red_pipe.goal_remainder).to eq 0
        expect(undrilled_cap.goal_remainder).to eq 0
        expect(cap.goal_remainder).to eq 0
        expect(screen.goal_remainder).to eq 0
        expect(beveled_washer.goal_remainder).to eq 0
        expect(male_adapter.goal_remainder).to eq 0
        expect(locknut.goal_remainder).to eq 0
        expect(black_washer.goal_remainder).to eq 0
        expect(cartridge_assembled.goal_remainder).to eq 0
        expect(faucet_w_washers.goal_remainder).to eq 0
        expect(faucet_adapter.goal_remainder).to eq 0
        expect(membrane_w_both.goal_remainder).to eq 0
        expect(body_w_ring.goal_remainder).to eq 0
        expect(head.goal_remainder).to eq 0
        expect(body.goal_remainder).to eq 0
        expect(body_o_ring.goal_remainder).to eq 0
        expect(membrane_w_thick.goal_remainder).to eq 0
        expect(thin_o_ring.goal_remainder).to eq 0
        expect(membrane.goal_remainder).to eq 0
        expect(thick_o_ring.goal_remainder).to eq 0
        expect(faucet.goal_remainder).to eq 0

        expect(sam3.available_count).to eq 1470
        expect(outflow.available_count).to eq 239
        expect(cartridge.available_count).to eq 283
        expect(blue.available_count).to eq 38
        expect(red.available_count).to eq 40
        expect(pipe.available_count).to eq 1
        expect(green.available_count).to eq 160
        expect(cap_w_screen.available_count).to eq 418
        expect(blue_pipe.available_count).to eq 121
        expect(elbow.available_count).to eq 118
        expect(bulkhead.available_count).to eq 166
        expect(red_pipe.available_count).to eq 97
        expect(undrilled_cap.available_count).to eq 0
        expect(cap.available_count).to eq 516
        expect(screen.available_count).to eq 7110
        expect(beveled_washer.available_count).to eq 1624
        expect(male_adapter.available_count).to eq 61
        expect(locknut.available_count).to eq 647
        expect(black_washer.available_count).to eq 6256
        expect(cartridge_assembled.available_count).to eq 608
        expect(faucet_w_washers.available_count).to eq 0
        expect(faucet_adapter.available_count).to eq 496
        expect(membrane_w_both.available_count).to eq 0
        expect(body_w_ring.available_count).to eq 32
        expect(head.available_count).to eq 52
        expect(body.available_count).to eq 0
        expect(body_o_ring.available_count).to eq 71
        expect(membrane_w_thick.available_count).to eq 32
        expect(thin_o_ring.available_count).to eq 0
        expect(membrane.available_count).to eq 0
        expect(thick_o_ring.available_count).to eq 18
        expect(faucet.available_count).to eq 8119

        job.perform_now

        expect(sam3.reload.goal_remainder).to eq 1010
        expect(outflow.reload.goal_remainder).to eq 771
        expect(cartridge.reload.goal_remainder).to eq 727
        expect(blue.reload.goal_remainder).to eq 733
        expect(red.reload.goal_remainder).to eq 731
        expect(pipe.reload.goal_remainder).to eq 48
        expect(green.reload.goal_remainder).to eq 611
        expect(cap_w_screen.reload.goal_remainder).to eq 315
        expect(blue_pipe.reload.goal_remainder).to eq 612
        expect(elbow.reload.goal_remainder).to eq 1346
        expect(bulkhead.reload.goal_remainder).to eq 565
        expect(red_pipe.reload.goal_remainder).to eq 634
        expect(undrilled_cap.reload.goal_remainder).to eq 0
        expect(cap.reload.goal_remainder).to eq 0
        expect(screen.reload.goal_remainder).to eq 0
        expect(beveled_washer.reload.goal_remainder).to eq 0
        expect(male_adapter.reload.goal_remainder).to eq 504
        expect(locknut.reload.goal_remainder).to eq 0
        expect(black_washer.reload.goal_remainder).to eq 0
        expect(cartridge_assembled.reload.goal_remainder).to eq 119
        expect(faucet_w_washers.reload.goal_remainder).to eq 727
        expect(faucet_adapter.reload.goal_remainder).to eq 231
        expect(membrane_w_both.reload.goal_remainder).to eq 119
        expect(body_w_ring.reload.goal_remainder).to eq 87
        expect(head.reload.goal_remainder).to eq 67
        expect(body.reload.goal_remainder).to eq 87
        expect(body_o_ring.reload.goal_remainder).to eq 16
        expect(membrane_w_thick.reload.goal_remainder).to eq 87
        expect(thin_o_ring.reload.goal_remainder).to eq 119
        expect(membrane.reload.goal_remainder).to eq 87
        expect(thick_o_ring.reload.goal_remainder).to eq 69
        expect(faucet.reload.goal_remainder).to eq 0
      end
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

    it 'only accesses technologies with set goals' do
    end
  end

  describe '#increase_assembly_item_goal(assembly)' do
  end

  describe '#increase_material_goal(part)' do
  end
end
