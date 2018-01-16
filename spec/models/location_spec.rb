require 'rails_helper'

RSpec.describe Location, type: :model do
  let(:location) { create :location }

  describe "must be valid" do
    let(:no_name) { build :location, name: nil }
    let(:no_addr) { build :location, address1: nil }
    let(:no_city) { build :location, city: nil }
    let(:no_state) { build :location, state: nil }
    let(:no_zip) { build :location, zip: nil }

    it "in order to save" do
      expect(location.save).to eq true
      expect { no_name.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect(no_addr.save).to be_falsey
      expect(no_city.save).to be_falsey
      expect(no_state.save).to be_falsey
      expect(no_zip.save).to be_falsey
    end
  end
end