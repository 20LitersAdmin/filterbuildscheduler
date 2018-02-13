require 'rails_helper'

RSpec.describe Count, type: :model do
  let(:inventory) { create :inventory }
  let(:count_part) { create :count_part, inventory: inventory }
  let(:count_comp) { create :count_comp, inventory: inventory }
  let(:count_mat) { create :count_mat, inventory: inventory }

  let(:technology) { create :technology }
  let(:part) { create :part }
  let(:tech_part) { create :tech_part, technology: technology, part: part }

  let(:count_part2) { create :count_part, part: part, inventory: inventory }
  let(:part2) { create :part, quantity_per_box: 10 }

  let(:part_w_min) { create :part, minimum_on_hand: 300 }
  let(:tech_part_w_min) { create :tech_part, technology: technology, part: part_w_min }
  let(:count_part_low) { create :count_part, loose_count: 150, unopened_boxes_count: 1, part: part_w_min }
  let(:count_part_high) { create :count_part, loose_count: 550, unopened_boxes_count: 12, part: part_w_min }
  

  describe "must be valid" do
    let(:no_inv) { build :count_part, inventory_id: nil }
    let(:no_loose) { build :count_part, loose_count: nil, inventory: inventory }
    let(:no_box) { build :count_part, unopened_boxes_count: nil, inventory: inventory }
    let(:no_extrap) { build :count_part, extrapolated_count: nil, inventory: inventory }

    it "in order to save" do
      expect { no_inv.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_loose.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_box.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_extrap.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
    end
  end

  describe "#item" do
    it "can return the associated model" do
      expect(count_part.item).to be_kind_of(Part)
      expect(count_comp.item).to be_kind_of(Component)
      expect(count_mat.item).to be_kind_of(Material)
    end
  end

  describe "#name" do
    it "returns the associated model's name value" do
      expect(count_part2.name).to equal(part.name)
    end
  end

  describe "#type" do
    it "returns a string indicating the item" do
      expect(count_part.type).to eq("part")
      expect(count_comp.type).to eq("component")
      expect(count_mat.type).to eq("material")
    end
  end

  describe "#tech_names" do
    it "returns a string of 'not associated' if there is no technologies assicated with the item" do
      expect(count_part.tech_names).to eq("not associated")
    end

    it "returns a string that lists the associated technologies" do
      count_part2.item.technologies << technology
      expect(count_part2.tech_names).to eq(technology.name)
    end
  end

  describe "#box_count" do
    let(:count_part3) { create :count_part, part: part2, unopened_boxes_count: 5 }

    it "calculates the individual items based upon the quantity_per_box of the associated item" do
      expect(count_part3.box_count).to eq(50)
    end
  end

  describe "#available" do
    let(:count_part3) { create :count_part, part: part2, unopened_boxes_count: 5, loose_count: 10 }
    
    it "calculates the number of items available" do
      expect(count_part3.available).to eq(60)
    end
  end

  describe "#diff_from_previous" do
    let(:inventory_prev) { build :inventory, date: Date.today - 2.days }
    let(:count_part_prev) { build :count_part, part: part, inventory: inventory_prev, loose_count: count_part2.loose_count - 5, unopened_boxes_count: count_part2.unopened_boxes_count - 4 }
    
    it "returns an error when no field is provided" do
      expect { count_part.diff_from_previous }.to raise_error(ArgumentError)
    end

    it "returns the current count if there is no previous inventory" do
      expect(count_part2.diff_from_previous("loose")).to eq(count_part2.loose_count)
      expect(count_part2.diff_from_previous("box")).to eq(count_part2.unopened_boxes_count)
    end

    it "returns the diff from the previous count" do
      inventory_prev.save
      count_part_prev.save
      expect(count_part2.diff_from_previous("loose")).to eq(5)
      expect(count_part2.diff_from_previous("box")).to eq(4)
    end
  end

  describe "#total" do
    let(:count_part3) { create :count_part, part: part2, inventory: inventory, unopened_boxes_count: 5, loose_count: 10, extrapolated_count: 100 }
    
    it "returns a string of 'Not Finalized' if the inventory isn't complete" do
      expect(count_part.total).to eq("Not Finalized")
    end

    it "returns the available and extrapolated_count if the inventory is complete" do
      inventory.update(completed_at: Time.now)
      expect(count_part3.total).to eq(160)
    end
  end

  describe "#sort_by_user" do
    let(:user) { create :user }
    let(:count_part3) { create :count_part, user: user}
    
    it "returns 1 if user_id.present?" do
      expect(count_part.sort_by_user).to eq(0)
      expect(count_part3.sort_by_user).to eq(1)
    end
  end

  describe "#reorder?" do
    
    it "returns false if the item is a component" do
      expect(count_comp.reorder?).to be_falsey
    end

    it "returns true if the part needs to be reordered" do
      expect(count_part_low.reorder?).to eq true
    end
  end

  describe "#weeks_to_out" do
    let(:count_part_out) { create :count_part, loose_count: 0, unopened_boxes_count: 0 }

    it "returns 0 if loose_count and box_count are 0" do
      expect(count_part_out.weeks_to_out).to eq 0
    end

    it "returns a float that represents the weeks until the product runs out" do
      part_w_min.save
      tech_part_w_min.save
      expect(count_part_high.weeks_to_out).to eq 2248.0
    end
  end
end