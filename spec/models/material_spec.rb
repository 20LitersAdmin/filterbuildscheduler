require 'rails_helper'

RSpec.describe Material, type: :model do
  let(:material) { create :material }

  describe "must be valid" do
    let(:no_name) { build :material, name: nil }
    let(:no_add_cost) { build :material, additional_cost_cents: nil }
    let(:no_price) { build :material, price_cents: nil }
    let(:no_minimum) { build :material, minimum_on_hand: nil }

    let(:negative_price) { build :material, price_cents: -300 }
    let(:negative_add_cost) { build :material, additional_cost_cents: -450 }

    it "in order to save" do
      expect(material.save).to eq true
      expect { no_name.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_add_cost.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_price.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_minimum.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
    end

    it "prices must be positive" do
      expect(negative_price.save).to be_falsey
      expect(negative_add_cost.save).to be_falsey
    end
  end
end