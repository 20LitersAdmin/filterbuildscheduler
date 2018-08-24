# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Component, type: :model do
  let(:component) { create :component }

  describe "must be valid" do
    let(:no_name) { build :component, name: nil}

    it "in order to save" do
      expect(component.save).to eq true
      expect { no_name.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
    end
  end
end
