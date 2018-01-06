require 'rails_helper'

RSpec.describe Event, type: :model do
  let(:event) { create :event }

  let(:no_starttime)        { build :event, start_time: nil, end_time: nil }
  let(:no_endtime)          { build :event, end_time: nil }
  let(:no_minleaders)       { build :event, min_leaders: nil }
  let(:no_maxleaders)       { build :event, max_leaders: nil }
  let(:no_minregistrations) { build :event, min_registrations: nil }
  let(:no_maxregistrations) { build :event, max_registrations: nil }
  
  describe "must be valid" do
    let(:unsaved_event)         { build :event }
    let(:no_title)              { build :event, title: nil }
    let(:no_location)           { build :event, location_id: nil }
    let(:no_technology)         { build :event, technology_id: nil }
    let(:no_privacy)            { build :event, is_private: nil }
    let(:no_itemgoal)           { build :event, item_goal: nil }
    let(:no_technologiesbuilt)  { build :event, technologies_built: nil }
    let(:no_boxespacked)        { build :event, boxes_packed: nil }

    it "in order to save" do
      expect(unsaved_event.save).to eq true
      expect(no_starttime.save).to be_falsey
      expect(no_endtime.save).to be_falsey
      expect(no_title.save).to be_falsey
      expect(no_location.save).to be_falsey
      expect(no_technology.save).to be_falsey
      expect { no_privacy.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_itemgoal.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect(no_technologiesbuilt.save).to be_falsey
      expect(no_boxespacked.save).to be_falsey
      expect(no_minleaders.save).to be_falsey
      expect(no_maxleaders.save).to be_falsey
      expect(no_minregistrations.save).to be_falsey
      expect(no_maxregistrations.save).to be_falsey
    end
  end

  describe "#dates_are_valid?" do
    let(:same_times) { build :event, start_time: Time.now, end_time: Time.now }
    let(:bad_times) { build :event, start_time: Time.now, end_time: Time.now - 3.hours }
    
    it "must have start and end times" do
      expect(no_starttime.dates_are_valid?).to eq nil
      expect(no_endtime.dates_are_valid?).to eq nil
      expect(event.dates_are_valid?).to eq nil
    end

    it "must have a start time that comes before end time" do
      same_times.save
      bad_times.save
      expect(same_times.errors.messages[:end_time]).to eq ["must be after start time"]
      expect(bad_times.errors.messages[:end_time]).to eq ["must be after start time"]
    end
  end

  describe "#registrations_are_valid?" do
    let(:same_registrations) { build :event, min_registrations: 3, max_registrations: 3 }
    let(:less_registrations) { build :event, min_registrations: 23, max_registrations: 3 }

    let(:event2) { create :event }

    let(:reg1) { create :registration, event: event2, guests_registered: 10 }
    let(:reg2) { create :registration, event: event2, guests_registered: 10 }
    let(:reg3) { create :registration, event: event2, guests_registered: 10 }

    it "must have min and max registrations" do
      expect(event.registrations_are_valid?).to eq nil
      expect(no_minleaders.registrations_are_valid?).to eq nil
      expect(no_maxleaders.registrations_are_valid?).to eq nil
    end

    it "must have a min registration that is less than the max registrations" do
      expect(same_registrations.registrations_are_valid?).to eq nil
      less_registrations.save
      expect(less_registrations.errors.messages[:max_registrations]).to eq ["must be greater than min registrations"]
    end

    it "can't have more registrations than the max" do
      event2.registrations << reg1
      event2.registrations << reg2
      event2.registrations << reg3
      event2.save
      expect(event2.errors.messages[:max_registrations]).to eq ['there are more registered attendees than the event max registrations']
    end
  end

  describe "#leaders_are_valid?" do
    let(:same_leaders) { build :event, min_leaders: 2, max_leaders: 2 }
    let(:less_leaders) { build :event, min_leaders: 23, max_leaders: 2 }

    let(:event3) { create :event }

    let(:reg4) { create :registration_leader, event: event3 }
    let(:reg5) { create :registration_leader, event: event3 }
    let(:reg6) { create :registration_leader, event: event3 }

    it "must have min and max leaders" do
      expect(event.leaders_are_valid?).to eq nil
      expect(no_minleaders.leaders_are_valid?).to eq nil
      expect(no_maxleaders.leaders_are_valid?).to eq nil
    end
    
    it "must have a min leader that is less than the max leader" do
      expect(same_leaders.leaders_are_valid?).to eq nil
      less_leaders.save
      expect(less_leaders.errors.messages[:max_leaders]).to eq ["must be greater than min leaders"]
    end

    it "can't have more leader registrations than the max" do
      event3.registrations << reg4
      event3.registrations << reg5
      event3.registrations << reg6
      event3.save
      expect(event3.errors.messages[:max_leaders]).to eq ['there are more registered leaders than the event max leaders']
    end
  end

  describe '#total_registered' do
    let(:user1) { create :user }
    let(:user2) { create :user }
    let(:user3) { create :user }

    it 'gives 0 when there are no registrations' do
      expect(event.total_registered).to eq(0)
    end

    it 'adds the number of guests and users' do
      Registration.create user: user1, event: event, guests_registered: 3
      Registration.create user: user2, event: event, guests_registered: 0
      expect(event.total_registered).to eq(5)
    end

    fit 'takes a scope to handle only_deleted records' do
      expect(event.total_registered("only_deleted")).to eq(0)

      Registration.create user: user3, event: event, guests_registered: 3, deleted_at: Time.now
      expect(event.total_registered("only_deleted")).to eq(4)
    end
  end

  describe "#non_leaders_registered" do
    
    
  end
end
