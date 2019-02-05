# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExtrapolateTechnologyPart, type: :model do
  let(:tech_part) { create :tech_part }

  describe 'must be valid' do
    let(:no_tech) { build :tech_part, technology: nil }
    let(:no_part) { build :tech_part, part: nil }
    let(:no_val) { build :tech_part, parts_per_technology: nil }
    let(:not_positive) { build :tech_part, parts_per_technology: -1.123 }

    it 'in order to save' do
      expect(tech_part.save).to eq true
      expect { no_tech.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_part.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_val.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
    end

    it 'parts_per_technology must be positive' do
      expect(not_positive.save).to be_falsey
    end
  end
end
