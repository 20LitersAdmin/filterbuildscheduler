require 'rails_helper'

RSpec.describe ExtrapolateMaterialPart, type: :model do
  let(:material_part) { create :material_part }

  describe "must be valid" do
    let(:no_material) { build :material_part, material_id: nil }
    let(:no_part) { build :material_part, part_id: nil }
    let(:no_val) { build :material_part, parts_per_material: nil }
    let(:not_integer) { build :material_part, parts_per_material: 1.24 }

    it "in order to save" do
      expect(material_part.save).to eq true
      expect { no_material.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_part.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_val.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
    end

    it "parts_per_material must be an integer" do
      expect(not_integer.save).to be_falsey
    end
  end
end