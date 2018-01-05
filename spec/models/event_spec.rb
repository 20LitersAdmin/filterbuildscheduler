require 'rails_helper'

RSpec.describe Event, type: :model do
  describe '#total_registered' do
    let(:event) { create :event }
    let(:user1) { create :user }
    let(:user2) { create :user }

    it 'gives 0 when there are no registrations' do
      expect(event.total_registered).to eq(0)
    end

    it 'adds the number of guests and users' do
      Registration.create user: user1, event: event, guests_registered: 3
      Registration.create user: user2, event: event, guests_registered: 0
      expect(event.total_registered).to eq(5)
    end

    
  end
end
