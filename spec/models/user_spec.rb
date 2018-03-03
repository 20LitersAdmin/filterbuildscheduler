require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user1) { create :user }

  describe "must be valid" do
    let(:good_user) {build :user }
    let(:blank_password) { build :user, password: ""}
    let(:no_fname) { build :user, fname: nil }
    let(:no_lname) { build :user, lname: nil }
    let(:no_email) { build :user, email: nil }
    
    it "in order to save" do
      expect(good_user.save).to eq true
      expect(blank_password.save).to eq true 
      expect(no_fname.save).to eq false
      expect(no_lname.save).to eq false
      expect(no_email.save).to eq false
    end
  end

  describe "#ensure_authentication_token" do
    subject { user1.authentication_token }
    it { should_not be nil }
  end

  describe "#update_kindful" do
    let(:user2) { build :user }

    it 'takes user data and sends it to kindful_client' do
      expect_any_instance_of( KindfulClient ).to receive(:import_user).with(user2)
      user2.save
    end
  end

  describe "#name" do
    it 'concatentates fname and lname' do
      expect(user1.name).to eq("#{user1.fname} #{user1.lname}")
    end
  end

  describe "#can_lead_event?" do
    let(:event) { create :event }
    let(:qualified) { create :leader }
    let(:unqualified) { create :user }

    it "can lead an event when the join table has a record" do
      qualified.technologies << event.technology
      expect(qualified.technologies.exists?(event.technology.id)).to be_truthy
      expect(qualified.can_lead_event?(event)).to be_truthy
      expect(unqualified.technologies.exists?(event.technology.id)).to be_falsey
      expect(unqualified.can_lead_event?(event)).to be_falsey
    end

    it "can't lead an event if they aren't a leader" do
      qualified.technologies << event.technology
      expect(qualified.is_leader).to be_truthy
      expect(qualified.can_lead_event?(event)).to be_truthy
      expect(unqualified.is_leader).to be_falsey
      expect(unqualified.can_lead_event?(event)).to be_falsey
    end
  end

  describe 'check_phone_format' do
    let(:good_phone) { build :user, phone: "(616) 555-1212"}
    let(:bad_phone) { build :user, phone: "(616;) 555=1212&$$$" }
    let(:text_phone) { build :user, phone: "DELETE BobbyTables!"}

    it 'accepts properly formatted phone #s' do
      good_phone.save

      expect(good_phone.phone).to eq '(616) 555-1212'
    end

    it 'strips bad characters from bad phone #s' do
      bad_phone.save
      text_phone.save

      expect(bad_phone.phone).to eq '(616) 5551212'
      expect(text_phone.phone).to eq ' '
    end
  end

  describe 'available_events' do
    let(:event1) { create :event, start_time: Time.now - 30.minutes }
    let(:event2) { create :event, start_time: Time.now }
    let(:private_event) { create :event, is_private: true }

    it 'shows all public events' do
      event1
      event2
      private_event

      expect(user1.available_events.count).to eq(2)
    end

    it 'shows all events I have registered for' do
      Registration.create user: user1, event: private_event

      expect(user1.available_events).to eq([private_event])
    end

    it 'shows all public events and all events I have registered for' do
      event1
      event2
      Registration.create user: user1, event: private_event

      expect(user1.available_events).to include(event1)
      expect(user1.available_events).to include(event2)
      expect(user1.available_events).to include(private_event)
    end
  end
end
