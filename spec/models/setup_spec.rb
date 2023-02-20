# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Setup, type: :model do
  let(:event) { create :event }
  let(:user) { create :setup_crew }
  let(:setup) { build :setup, event:, creator: user }
  let(:no_date) { build :setup, event:, creator: user, date: nil }
  let(:no_event) { build :setup, event: nil, creator: user, date: Faker::Time.between_dates(from: Time.now + 2.days, to: Time.now + 4.days, period: :morning) }
  let(:date_after_event) { build :setup, event:, creator: user, date: Time.now + 30.days }

  describe 'must be valid' do
    let(:no_creator) { build :setup, event:, creator: nil }

    it 'in order to save' do
      expect(setup.valid?).to eq true
      no_event.valid?
      expect(no_event.errors[:event][0]).to eq 'must exist'
      no_creator.valid?
      expect(no_creator.errors[:creator][0]).to eq 'must exist'
      no_date.valid?
      expect(no_date.errors[:date][0]).to eq "can't be blank"
      date_after_event.valid?
      expect(date_after_event.errors[:date][0]).to eq 'Must be before event'
    end
  end

  it 'doesn\'t need users' do
    setup.save
    expect(setup.users).to eq []
  end

  describe '#crew' do
    context 'when no users are associated' do
      it 'returns NO ONE' do
        expect(setup.crew).to eq 'NO ONE'
      end
    end

    context 'when users are assigned' do
      let(:setup_with_users) { create :setup_with_users, event:, creator: user }

      it 'returns a string of first names' do
        setup_with_users.users.pluck(:fname).each do |fname|
          expect(setup_with_users.crew).to include fname
        end
      end
    end
  end

  describe '#in_the_future?' do
    context 'when date is not present' do
      it 'returns false' do
        expect(no_date.in_the_future?).to be_falsey
      end
    end

    context 'when date is greater than the current time' do
      it 'returns true' do
        expect(setup.in_the_future?).to be_truthy
      end
    end

    context 'when date is less than the current time' do
      let(:setup_in_past) { build :setup_in_past, event:, creator: user }
      it 'returns false' do
        expect(setup_in_past.in_the_future?).to eq false
      end
    end
  end

  describe '#summary' do
    context 'when setup happens the same day as the event' do
      let(:setup_day_of) { create :setup_day_of }

      it 'includes the date and both times' do
        expect(setup_day_of.summary).to include setup_day_of.date.strftime('%a, %-m/%-d')
        expect(setup_day_of.summary).to include setup_day_of.date.strftime('%-l:%M%P')
        expect(setup_day_of.summary).to include setup_day_of.event.start_time.strftime('%-l:%M%P')
      end
    end

    context 'when setup happens before the day of the event' do
      it 'lists the date and time of setup, and just the date of the event' do
        expect(setup.summary).to include setup.date.strftime('%a, %-m/%-d')
        expect(setup.summary).to include setup.date.strftime('%-l:%M%P')
        expect(setup.summary).to include setup.event.start_time.strftime('%-m/%-d')
      end
    end
  end

  describe '#end_time' do
    context 'when date is present' do
      it 'returns a time one hour later than the date value' do
        expect(setup.end_time).to eq setup.date + 1.hour
      end
    end

    context 'when date is not present' do
      it 'returns nil' do
        expect(no_date.end_time).to eq nil
      end
    end
  end

  private

  describe '#dates_present?' do
    context 'when setup.date is not present' do
      it 'returns false' do
        expect(no_date.__send__(:dates_present?)).to be_falsey
      end
    end

    context 'when event.start_time is not present' do
      it 'returns false' do
        expect(no_event.__send__(:dates_present?)).to be_falsey
      end
    end

    context 'when setup.date and event.start_time are both present' do
      it 'returns true' do
        expect(setup.__send__(:dates_present?)).to be_truthy
      end
    end
  end

  describe '#date_must_be_before_event' do
    context 'when setup.date is before event.start_time' do
      it 'does nothing' do
        expect(setup.date < setup.event.start_time).to be_truthy
        setup.valid?
        expect(setup.errors.any?).to be_falsey
      end
    end

    context 'when setup.date is after event.start_time' do
      it 'adds an error to :date' do
        expect(date_after_event.date < date_after_event.event.start_time).to be_falsey

        date_after_event.valid?
        expect(date_after_event.errors[:date][0]).to eq 'Must be before event'
      end
    end
  end
end
