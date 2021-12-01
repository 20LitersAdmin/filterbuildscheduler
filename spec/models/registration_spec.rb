# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Registration, type: :model do
  let(:event) { create :event }
  let(:user) { create :user }
  let(:registration) { create :registration, event: event, user: user }
  let(:registration_attended) { create :registration_attended }
  let(:registration_leader) { create :registration_leader, event: event }

  describe 'must be valid' do
    let(:no_user) { build :registration, user_id: nil }
    let(:no_event) { build :registration, event_id: nil }

    it 'in order to save' do
      expect(registration.save).to eq true

      expect { no_user.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_event.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
    end
  end

  describe '#humand_date' do
    it 'returns created_at in a format' do
      expect(registration.human_date).to eq registration.created_at.strftime('%-m/%-d/%Y %H:%M')
    end
  end

  describe '#role' do
    context 'when registration is for a leader' do
      it 'returns leader' do
        expect(registration_leader.role).to eq 'leader'
      end
    end

    context 'when registration is for a builder' do
      it 'returns builder' do
        expect(registration.role).to eq 'builder'
      end
    end
  end

  describe '#total_registered' do
    it 'returns guests_registered + 1' do
      expect(registration.total_registered).to eq registration.guests_registered + 1
    end
  end

  describe '#total_attended' do
    context 'when attended is false' do
      it 'returns 0' do
        expect(registration.total_attended).to eq 0
      end
    end

    context 'when attended is true' do
      it 'returns guests_attended + 1' do
        expect(registration_attended.total_attended).to eq registration_attended.guests_attended + 1
      end
    end
  end

  describe '#waiver_accepted' do
    it 'should delegate waiver_accepted to User' do
      user.signed_waiver_on = nil

      expect(registration.waiver_accepted?).to be false

      user.signed_waiver_on = Time.now

      expect(registration.waiver_accepted?).to be true
    end
  end
end
