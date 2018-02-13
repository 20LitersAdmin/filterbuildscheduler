require 'rails_helper'

RSpec.describe Registration, type: :model do
  let(:event) { create :event }
  let(:user) { create :user }
  let(:registration) { create :registration, event: event, user: user }
  let(:registration_attended) { create :registration_attended }
  let(:registration_leader) { create :registration_leader, event: event }

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
    user.signed_waiver_on = nil

    expect(registration.waiver_accepted?).to be false

    user.signed_waiver_on = Time.now

    expect(registration.waiver_accepted?).to be true
  end

  describe "#under_max_registrations?" do
    let(:big_reg) { build :registration, guests_registered: 29, event: event, user: user }

    it "doesn't add an error if the registration is for a leader" do
      registration_leader.under_max_registrations?
      expect(registration_leader.errors.messages.count).to eq 0
    end

    it "doesn't add an error if the registration doesn't exceed the max" do
      registration.under_max_registrations?
      expect(registration.errors.messages.count).to eq 0
    end

    it "adds an error to User#email if the registration will exceed the max" do
      user
      event
      big_reg.under_max_registrations?
      expect(big_reg.errors.messages[:guests_registered][0]).to eq "maximum registrations exceeded by 5 for event"
    end
  end

  describe "#under_max_leaders?" do
    let(:registration_leader2) { create :registration_leader, event: event }
    let(:registration_leader3) { build :registration_leader, event: event }

    it "returns nil if the registration is not a leader" do
      registration_leader.under_max_leaders?
      expect(registration_leader.errors.messages.count).to eq 0
    end

    it "returns nil if the registration doesn't exceed the leader max" do
      registration_leader.under_max_leaders?
      expect(registration_leader.errors.messages.count).to eq 0
    end

    it "adds an error to Registration#leader if the registration will exceed the max" do
      event
      registration_leader
      registration_leader2
      registration_leader3.under_max_leaders?
      expect(registration_leader3.errors.messages[:leader][0]).to eq "maximum leaders exceeded for event"
    end
  end
end