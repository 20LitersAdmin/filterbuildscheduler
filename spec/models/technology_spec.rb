# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Technology, type: :model do
  let(:technology) { create :technology }

  describe "must be valid" do
    let(:no_name) { build :technology, name: nil }
    let(:no_people) { build :technology, people: nil }
    let(:no_lifespan) { build :technology, lifespan_in_years: nil }

    it "in order to save" do
      expect(technology.save).to eq true

      expect { no_name.save!(validate: false ) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_people.save!(validate: false ) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_lifespan.save!(validate: false ) }.to raise_error ActiveRecord::NotNullViolation
    end
  end

  describe "#leaders" do
    let(:leader) { create :leader }
    let(:user) { create :user }

    it "should return qualified leaders" do
      leader.technologies << technology
      user.technologies << technology
      leader.save
      user.save
      technology.save
      expect(technology.leaders).to include(leader)
      expect(technology.leaders).not_to include(user)
    end
  end

  describe "#primary_component" do
    let(:component_ct) { create :component_ct }
    let(:component) { create :component }


    it "finds the primary component" do
      technology.components << component_ct
      technology.components << component

      expect(technology.primary_component).to eq component_ct
      expect(technology.primary_component).not_to eq component
    end
  end
end
