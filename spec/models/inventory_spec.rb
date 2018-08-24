# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Inventory, type: :model do
  let(:inventory) { create :inventory }
  let(:manual) { create :inventory_man }
  let(:shipping) { create :inventory_ship }
  let(:receiving) { create :inventory_rec }
  let(:event) { create :inventory_event }

  describe "must be valid" do
    let(:no_receiving) { build :inventory_rec, receiving: nil }
    let(:no_shipping) { build :inventory_ship, shipping: nil }
    let(:no_manual) { build :inventory_man, manual: nil }
    let(:no_date) { build :inventory, date: nil }

    it "in order to save" do
      expect(inventory.save).to eq true
      expect { no_receiving.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_shipping.save!(validate: false ) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_manual.save!(validate: false)}.to raise_error ActiveRecord::NotNullViolation
      expect { no_date.save!(validate: false)}.to raise_error ActiveRecord::NotNullViolation
    end
  end

  describe "#type" do
    it "returns a string indicating the type of event" do
      expect(manual.type).to eq("Manual Inventory")
      expect(shipping.type).to eq("Items Shipped")
      expect(receiving.type).to eq("Items Received")
      expect(event.type).to eq("Event Based")
    end
  end

  describe "#type_for_params" do
    it "returns a string indicating the type of event" do
      expect(manual.type_for_params).to eq("manual")
      expect(shipping.type_for_params).to eq("shipping")
      expect(receiving.type_for_params).to eq("receiving")
      expect(event.type_for_params).to eq("event")
    end
  end

  describe "#has_items_below_minimum?" do
    let(:part_w_min) { create :part, minimum_on_hand: 300 }
    let(:count_part_low) { create :count_part, loose_count: 150, unopened_boxes_count: 0, part: part_w_min, inventory: inventory }

    let(:inventory2) { create :inventory }
    let(:count_part_high) { create :count_part, loose_count: 350, unopened_boxes_count: 5, part: part_w_min, inventory: inventory2 }

    it "returns true if any of the child count records need reordering" do
      inventory.counts << count_part_low
      inventory2.counts << count_part_high
      expect(inventory.has_items_below_minimum?).to eq true
      expect(inventory2.has_items_below_minimum?).to eq false
    end
  end

  describe "#item_count" do
    let(:user) { create :user }

    it "returns the number of counts that have a user_id" do
      parts_with_user_id = create_list(:count_part, 4, inventory: inventory, user: user)
      components_with_user_id = create_list(:count_comp, 3, inventory: inventory, user: user)
      materials_with_user_id = create_list(:count_mat, 2, inventory: inventory, user: user)

      parts_wo_user_id = create_list(:count_part, 7, inventory: inventory)
      components_wo_user_id = create_list(:count_comp, 6, inventory: inventory)
      materials_wo_user_id = create_list(:count_mat, 5, inventory: inventory)
      
      expect(inventory.item_count).to eq(9)
    end
  end

  describe "#primary_counts" do
    let(:component) { create :component, completed_tech: true }

    it "returns the child counts that are components where completed_tech: true" do
      count_comps = create_list(:count_comp, 6, inventory: inventory)
      count_comps.last.update(component: component)


      expect(inventory.primary_counts.first).to eq(count_comps.last)
    end
  end
end
