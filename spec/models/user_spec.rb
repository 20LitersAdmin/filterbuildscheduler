require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user1) { create :user }

  describe '#events_available' do
    let(:event1) { create :event }
    let(:event2) { create :event }
    let(:private_event) { create :event, is_private: true }
    let(:user2) { create :user }

    it 'shows all public events' do
      event1
      event2
      create :event, is_private: true
      expect(user1.available_events).to eq([event1, event2])
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

  describe "update_kindful" do
    it 'takes user data and sends it to kindful_client' do
      @kindful_spy = spy
      expect(KindfulClient).to receive(:new).and_return(@kindful_spy)
      user1
      expect(@kindful_spy).to have_received(:update_user).with(user1)
    end
  end
end
