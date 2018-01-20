require 'rails_helper'

RSpec.describe Registration, type: :model do
  let(:registration) { create :registration }
  let(:registration_attended) { create :registration_attended }
  let(:registration_leader) { create :registration_leader }

  describe "must be valid" do
    let(:no_user) { build :registration, user_id: nil }
    let(:no_event) { build :registration, event_id: nil }

    it "in order to save" do
      expect(registration.save).to eq true

      expect { no_user.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_event.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
    end
  end

  it "should delegate waiver_accepted to User" do
    pending("I don't understand delegate")
    should delegate_method(:waiver_accepted).to(:user)
  end
end