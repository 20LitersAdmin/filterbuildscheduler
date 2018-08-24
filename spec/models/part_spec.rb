# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Part, type: :model do
  let(:part) { create :part }

  describe "must be valid" do
    let(:no_name) { build :part, name: nil }
    let(:no_add_cost) { build :part, additional_cost_cents: nil }
    let(:no_price) { build :part, price_cents: nil }
    let(:no_minimum) { build :part, minimum_on_hand: nil }

    let(:negative_add_cost) { build :part, additional_cost_cents: -765 }
    let(:negative_price) { build :part, price_cents: -299 }

    it "in order to save" do
      expect(part.save).to eq true

      expect { no_name.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_add_cost.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_price.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_minimum.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
    end

    it "prices can't be negative" do
      expect(negative_add_cost.save).to be_falsey
      expect(negative_price.save).to be_falsey
    end

    describe "#per_technology" do
      let(:part1) { create :part }
      let(:technology1) { create :technology }
      let(:tech_part1) { create :tech_part, part: part1, technology: technology1, parts_per_technology: 5 }

      let(:part2) { create :part }
      let(:component2) { create :component }
      let(:comp_part2) { create :comp_part, part: part2, component: component2, parts_per_component: 2 }

      let(:technology2) { create :technology }
      let(:tech_comp2) { create :tech_comp, component: component2, technology: technology2, components_per_technology: 2 }


      it "returns 0 if there's no extrapolate records to use" do
        expect(part.per_technology).to eq 0
      end

      it "uses parts_per_technology if it exists" do
        part1
        technology1
        tech_part1

        expect(part1.per_technology).to eq 5.0
      end

      it "uses parts_per_component, then components_per_technology if it needs to" do
        part2
        component2
        comp_part2
        technology2
        tech_comp2

        expect(part2.per_technology).to eq 4.0

      end

    end
  end
end
