# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Material, type: :model do
  let(:material) { create :material }

  describe 'must be valid' do
    let(:no_name) { build :material, name: nil }
    let(:no_price) { build :material, price_cents: nil }
    let(:no_minimum) { build :material, minimum_on_hand: nil }

    let(:negative_price) { build :material, price_cents: -300 }

    it 'in order to save' do
      expect(material.save).to eq true
      expect { no_name.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_price.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_minimum.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
    end

    it 'prices must be positive' do
      expect(negative_price.save).to be_falsey
    end
  end

  describe '#per_technology' do
    let(:part) { create :part }
    let(:material_part) { create :material_part, material: material, part: part, parts_per_material: 10 }

    let(:component) { create :component }
    let(:comp_part) { create :comp_part, part: part, component: component, parts_per_component: 5 }

    let(:technology) { create :technology }
    let(:tech_comp) { create :tech_comp, component: component, technology: technology, components_per_technology: 2 }

    it 'returns 0 if there is no part relationship' do
      expect(material.per_technology).to eq 0
    end

    it 'returns a float that represents the number of materials in a complete technology' do
      material
      part
      component
      technology
      material_part
      comp_part
      tech_comp

      expect(material.per_technology).to eq 1.0
    end
  end
end
