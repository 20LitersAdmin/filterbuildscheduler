# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Event, type: :model do
  let(:technology) { create :technology }
  let(:event) { create :event, technology: technology }
  let(:future_event) { create :event, technology: technology, start_time: Time.now + 2.days, end_time: Time.now + 2.days + 2.hours }
  let(:complete_event) { create :complete_event, technology: technology }

  let(:no_starttime)        { build :event, start_time: nil, end_time: nil }
  let(:no_endtime)          { build :event, end_time: nil }
  let(:no_minleaders)       { build :event, min_leaders: nil }
  let(:no_maxleaders)       { build :event, max_leaders: nil }
  let(:no_minregistrations) { build :event, min_registrations: nil }
  let(:no_maxregistrations) { build :event, max_registrations: nil }

  let(:user1) { create :user }
  let(:user2) { create :user }
  let(:user3) { create :user }

  let(:reg1) { build :registration, event: event, guests_registered: 19 }
  let(:reg2) { build :registration, event: event, guests_registered: 4 }

  let(:reg_del1) { build :registration, event: event, guests_registered: 19, deleted_at: Time.now }
  let(:reg_del2) { build :registration, event: event, guests_registered: 4, deleted_at: Time.now }

  let(:reg_leader1) { build :registration_leader, event: event }
  let(:reg_leader2) { build :registration_leader, event: event }
  let(:reg_leader3) { build :registration_leader, event: event }

  let(:reg_leader_del1) { build :registration_leader, event: event, deleted_at: Time.now }
  let(:reg_leader_del2) { build :registration_leader, event: event, deleted_at: Time.now }
  let(:reg_leader_del3) { build :registration_leader, event: event, deleted_at: Time.now }

  let(:component_ct) { create :component_ct }
  let(:tech_comp) { create :tech_comp, component: component_ct, technology: technology }

  describe 'must be valid' do
    let(:unsaved_event)         { build :event }
    let(:no_title)              { build :event, title: nil }
    let(:no_location)           { build :event, location_id: nil }
    let(:no_technology)         { build :event, technology_id: nil }
    let(:no_privacy)            { build :event, is_private: nil }
    let(:no_itemgoal)           { build :event, item_goal: nil }
    let(:no_technologiesbuilt)  { build :event, technologies_built: nil }
    let(:no_boxespacked)        { build :event, boxes_packed: nil }

    it 'in order to save' do
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

  describe '#dates_are_valid?' do
    let(:same_times) { build :event, start_time: Time.now, end_time: Time.now }
    let(:bad_times) { build :event, start_time: Time.now, end_time: Time.now - 3.hours }

    it 'must have start and end times' do
      expect(no_starttime.dates_are_valid?).to eq nil
      expect(no_endtime.dates_are_valid?).to eq nil
      expect(event.dates_are_valid?).to eq nil
    end

    it 'must have a start time that comes before end time' do
      same_times.save
      bad_times.save
      expect(same_times.errors.messages[:end_time]).to eq ['must be after start time']
      expect(bad_times.errors.messages[:end_time]).to eq ['must be after start time']
    end
  end

  describe '#registrations_are_valid?' do
    let(:same_registrations) { build :event, min_registrations: 3, max_registrations: 3 }
    let(:less_registrations) { build :event, min_registrations: 23, max_registrations: 3 }

    let(:event2) { create :event }

    let(:reg3) { build :registration, event: event2, guests_registered: 10 }
    let(:reg4) { build :registration, event: event2, guests_registered: 10 }
    let(:reg5) { build :registration, event: event2, guests_registered: 10 }

    it 'must have min and max registrations' do
      expect(event.registrations_are_valid?).to eq nil
      expect(no_minleaders.registrations_are_valid?).to eq nil
      expect(no_maxleaders.registrations_are_valid?).to eq nil
    end

    it 'must have a min registration that is less than the max registrations' do
      expect(same_registrations.registrations_are_valid?).to eq nil
      less_registrations.save
      expect(less_registrations.errors.messages[:max_registrations]).to eq ['must be greater than min registrations']
    end

    it 'can\'t have more registrations than the max' do
      event2.registrations << reg3
      event2.registrations << reg4
      event2.registrations << reg5
      expect(event2.save).to be_falsey
    end
  end

  describe '#leaders_are_valid?' do
    let(:same_leaders) { build :event, min_leaders: 2, max_leaders: 2 }
    let(:less_leaders) { build :event, min_leaders: 23, max_leaders: 2 }

    let(:event3) { create :event }

    let(:reg3) { build :registration_leader, event: event3 }
    let(:reg4) { build :registration_leader, event: event3 }
    let(:reg5) { build :registration_leader, event: event3 }

    it 'must have min and max leaders' do
      expect(event.leaders_are_valid?).to eq nil
      expect(no_minleaders.leaders_are_valid?).to eq nil
      expect(no_maxleaders.leaders_are_valid?).to eq nil
    end

    it 'must have a min leader that is less than the max leader' do
      expect(same_leaders.leaders_are_valid?).to eq nil
      less_leaders.save
      expect(less_leaders.errors.messages[:max_leaders]).to eq ['must be greater than min leaders']
    end

    it 'can\'t have more leader registrations than the max' do
      event3.registrations << reg3
      event3.registrations << reg4
      event3.registrations << reg5
      expect(event3.save).to be_falsey
    end
  end

  describe '#total_registered' do
    it 'gives 0 when there are no registrations' do
      expect(event.total_registered).to eq(0)
    end

    it 'adds the number of guests and users' do
      Registration.create user: user1, event: event, guests_registered: 3
      Registration.create user: user2, event: event, guests_registered: 0
      expect(event.total_registered).to eq(5)
    end

    it 'takes a scope to handle only_deleted records' do
      expect(event.total_registered("only_deleted")).to eq(0)

      Registration.create user: user3, event: event, guests_registered: 3, deleted_at: Time.now
      expect(event.total_registered("only_deleted")).to eq(4)
    end
  end

  describe "#builders_registered" do
    let(:user4) { create :user }
    it "gives 0 when there are no registrations" do
      expect(event.builders_registered.count).to eq 0
    end

    it "counts the number of registrations that aren't leaders" do
      reg7 = Registration.create user: user1, event: event, guests_registered: 3
      reg8 = Registration.create user: user2, event: event, guests_registered: 2
      reg9 = Registration.create user: user3, event: event, leader: true

      # Why does the first record get saved to the parent, but not the next 3??
      # event.registrations << reg7
      event.registrations << reg8
      event.registrations << reg9

      expect(event.builders_registered.count).to eq 2
      expect(event.total_registered_w_leaders).to eq 8
    end
  end

  describe "#leaders_registered" do
    let(:reg_non_leader) { build :registration, event: event }

    let(:user5) { create :user}

    it "gives 0 when there are no leaders registered" do
      reg_non_leader.save
      expect(event.leaders_registered.count).to eq(0)
    end

    it "counts the number of leaders registered for the event" do
      reg_leader1.save
      expect(event.leaders_registered.count).to eq(1)
      reg_leader2.save
      expect(event.leaders_registered.count).to eq(2)
    end
  end

  describe "#registrations_filled?" do
    it "returns true when the count of total_registered >= max_registrations" do
      event.registrations << reg1
      event.registrations << reg2
      expect(event.registrations_filled?).to eq true
    end

    it "returns false when the count of total_registered < max_registrations" do
      event.registrations << reg1
      expect(event.registrations_filled?).to be_falsey
    end
  end

  describe "#registrations_remaining" do
    it "returns the # of slots remaining for the event" do
      expect(event.registrations_remaining).to eq(25)
      event.registrations << reg1
      expect(event.registrations_remaining).to eq(5)
      event.registrations << reg2
      expect(event.registrations_remaining).to eq(0)
    end
  end

  describe "#does_not_need_leaders?" do
    it "returns true only if there are enough or more than enough leaders" do
      expect(event.does_not_need_leaders?).to be_falsey
      event.registrations << reg_leader1
      expect(event.does_not_need_leaders?).to be_falsey
      event.registrations << reg_leader2
      expect(event.does_not_need_leaders?).to eq true
      event.registrations << reg_leader3
      expect(event.does_not_need_leaders?).to eq true
    end
  end

  describe "#really_needs_leaders?" do
    let(:event2) { create :event, min_leaders: 2, max_leaders: 3 }

    it "returns true if there are less leaders registered than the min" do
      expect(event2.really_needs_leaders?).to eq true
      event2.registrations << reg_leader1
      expect(event2.really_needs_leaders?).to eq true
      event2.registrations << reg_leader2
      expect(event2.really_needs_leaders?).to be_falsey
      event2.registrations << reg_leader3
      expect(event2.really_needs_leaders?).to be_falsey
    end
  end

  describe "#needs_leaders?" do
    let(:event2) { create :event, min_leaders: 2, max_leaders: 3 }

    it "returns true if there are less leaders registered than the max" do
      expect(event2.needs_leaders?).to eq true
      event2.registrations << reg_leader1
      expect(event2.needs_leaders?).to eq true
      event2.registrations << reg_leader2
      expect(event2.needs_leaders?).to eq true
      event2.registrations << reg_leader3
      expect(event2.needs_leaders?).to be_falsey
    end
  end

  describe "#complete?" do
    it "returns true only if report-based fields are present and the event has already started" do
      expect(future_event.complete?).to be_falsey

      future_event.technologies_built = 30
      future_event.attendance = 20
      future_event.save
      expect(future_event.complete?).to be_falsey

      expect(complete_event.complete?).to eq true
    end
  end

  describe "#you_are_attendee" do
    let(:reg3) { build :registration, user: user1, event: event }
    let(:reg_del) { build :registration, user: user1, event: event, deleted_at: Time.now }

    it "checks to see if a user is registered as a non-leader" do
      expect(event.you_are_attendee(user1)).to be_falsey

      event.registrations << reg3
      expect(event.you_are_attendee(user1)).to eq " (including you)"
    end
  end

  describe "#you_are_leader" do
    let(:leader) { create :leader }
    let(:reg3) { build :registration, user: user1, event: event, leader: true }
    let(:reg4) { build :registration, user: leader, event: event, leader: true }
    let(:reg_del3) { build :registration, user: user1, event: event, leader: true, deleted_at: Time.now }
    let(:reg_del4) { build :registration, user: leader, event: event, leader: true, deleted_at: Time.now }

    it "checks to see if a user is a leader and is registered as a leader" do
      expect(event.you_are_leader(leader)).to be_falsey

      event.registrations << reg3
      expect(event.you_are_leader(user1)).to be_falsey

      event.registrations << reg4
      expect(event.you_are_leader(leader)).to eq " (including you)"
    end
  end

  describe "#technology_results" do
    let(:event_complete_no_ct) { create :complete_event }

    it "must be complete to run" do
      expect(event.technology_results).to eq(0)
      expect(future_event.technology_results).to eq(0)
    end

    it "must have a technology.primary_component to run" do
      expect(event_complete_no_ct.technology_results).to eq(0)
    end

    it "returns the number of individual technologies produced" do
      technology.components << component_ct
      expect(complete_event.technology_results).to eq(155)
    end
  end

  describe "#results_people" do
    let(:tech_no_ppl) { create :technology, people: 0 }
    let(:event2) { create :complete_event, technology: tech_no_ppl }

    it "must have a technology.people value greater than 0" do
      tech_no_ppl.components << component_ct
      expect(event2.results_people).to eq(0)
    end

    it "must have a technology_results value greater than 0" do
      expect(future_event.results_people).to eq(0)
    end

    it "returns the number of people served * technology_results" do
      technology.components << component_ct
      expect(complete_event.results_people).to eq(775)
    end
  end

  describe "#results_timespan" do
    let(:tech_no_lifespan) { create :technology, lifespan_in_years: 0 }
    let(:event2) { create :complete_event, technology: tech_no_lifespan }

    it "must have a technology.lifespan_in_years greater than 0" do
      tech_no_lifespan.components << component_ct
      expect(event2.results_timespan).to eq(0)
    end

    it "must have a technology_results value greater than 0" do
      expect(future_event.results_timespan).to eq(0)
    end

    it "returns the technology.lifespan_in_years" do
      technology.components << component_ct
      expect(complete_event.results_timespan).to eq(10)
    end
  end

  describe "#results_liters_per_day" do
    let(:tech_no_liters) { create :technology, liters_per_day: 0 }
    let(:event2) { create :complete_event, technology: tech_no_liters }

    it "must have a technology.liters_per_day greater than 0" do
      tech_no_liters.components << component_ct
      expect(event2.results_liters_per_day).to eq(0)
    end

    it "must have a technology_results value greater than 0" do
      expect(future_event.results_liters_per_day).to eq(0)
    end

    it "returns the liters per day * technology_results" do
      technology.components << component_ct
      expect(complete_event.results_liters_per_day).to eq(15500)
    end
  end
end
