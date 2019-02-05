# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExtrapolateTechnologyComponent, type: :model do
  let(:tech_comp) { create :tech_comp }

  describe 'must be valid' do
    let(:no_tech) { build :tech_comp, technology: nil }
    let(:no_component) { build :tech_comp, component: nil }
    let(:no_val) { build :tech_comp, components_per_technology: nil }
    let(:not_positive) { build :tech_comp, components_per_technology: -4.5322 }

    it 'in order to save' do
      expect(tech_comp.save).to eq true
      expect { no_tech.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_component.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_val.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
    end

    it 'components_per_technology must be positive' do
      expect(not_positive.save).to be_falsey
    end
  end
end
