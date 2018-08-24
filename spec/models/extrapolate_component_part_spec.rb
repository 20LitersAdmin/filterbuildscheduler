# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExtrapolateComponentPart, type: :model do
  let(:comp_part) { create :comp_part }
  
  describe "must be valid" do
    let(:no_comp) { build :comp_part, component: nil }
    let(:no_part) { build :comp_part, part: nil }
    let(:no_val) { build :comp_part, parts_per_component: nil }
    let(:not_integer) { build :comp_part, parts_per_component: 1.25 }
    
    it "in order to save" do
      expect(comp_part.save).to eq true
      expect { no_comp.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_part.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_val.save!(validate: false)  }.to raise_error ActiveRecord::NotNullViolation
    end

    it "parts_per_component must be an integer" do
      expect(not_integer.save).to be_falsey
    end
  end
end
