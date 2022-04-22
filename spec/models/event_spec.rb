# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Event, type: :model do
  let(:event) { create :event }
  let(:complete_event) { create :complete_event_technology }
  let(:complete_event_impact) { create :complete_event_impact }

  let(:no_starttime)        { build :event, start_time: nil, end_time: nil }
  let(:no_endtime)          { build :event, end_time: nil }
  let(:no_minleaders)       { build :event, min_leaders: nil }
  let(:no_maxleaders)       { build :event, max_leaders: nil }
  let(:no_minregistrations) { build :event, min_registrations: nil }
  let(:no_maxregistrations) { build :event, max_registrations: nil }

  let(:user) { create :user }
  let(:reg1) { build :registration, event: event, guests_registered: 19, user: user }
  let(:reg2) { build :registration, event: event, guests_registered: 9 }

  let(:reg_leader1) { build :registration_leader, event: event, guests_registered: 0 }
  let(:reg_leader2) { build :registration_leader, event: event, guests_registered: 0 }
  let(:reg_leader3) { build :registration_leader, event: event }

  describe 'must be valid' do
    let(:unsaved_event)         { build :event }
    let(:no_title)              { build :event, title: nil }
    let(:no_location)           { build :event, location_id: nil }
    let(:no_technology)         { build :event, technology_id: nil }
    let(:no_privacy)            { build :event, is_private: nil }
    let(:no_itemgoal)           { build :event, item_goal: nil }
    let(:no_technologiesbuilt)  { build :event, technologies_built: nil }
    let(:no_boxespacked)        { build :event, boxes_packed: nil }
    let(:no_impact_results)     { build :event, impact_results: nil }

    it 'in order to save' do
      expect(unsaved_event.save).to eq true
      expect(no_starttime.save).to be_falsey
      expect(no_endtime.save).to be_falsey
      expect(no_title.save).to be_falsey

      expect(no_minleaders.save).to be_falsey
      expect(no_maxleaders.save).to be_falsey
      expect(no_minregistrations.save).to be_falsey
      expect(no_maxregistrations.save).to be_falsey

      expect(no_technologiesbuilt.save).to be_falsey
      expect(no_boxespacked.save).to be_falsey
      expect(no_impact_results.save).to be_falsey

      expect { no_privacy.save!(validate: false) }
        .to raise_error ActiveRecord::NotNullViolation
      expect { no_itemgoal.save!(validate: false) }
        .to raise_error ActiveRecord::NotNullViolation
    end

    it 'doesn\'t need a technology' do
      expect(no_technology.save).to eq true
    end

    it 'doesn\'t need a location' do
      expect(no_location.save).to eq true
    end
  end

  describe '#builders_hours' do
    it 'returns number_of_builders_attended * length' do
      expect(event.builders_hours).to eq(event.number_of_builders_attended * event.length)
    end
  end

  describe '#builders_registered' do
    it 'returns the un-discarded builder records' do
      expect(event.builders_registered).to eq event.registrations.kept.builders
    end
  end

  describe '#builders_have_vs_total' do
    it 'returns a string' do
      expect(event.builders_have_vs_total.class).to eq String
    end
  end

  describe '#complete?' do
    it 'returns true only if report-based fields are present and the event has already started' do
      expect(event.complete?).to be_falsey

      event.technologies_built = 30
      event.attendance = 20
      event.save
      expect(event.complete?).to be_falsey

      expect(complete_event.complete?).to eq true
    end
  end

  describe '#does_not_need_leaders?' do
    it 'returns true only if there are enough or more than enough leaders' do
      expect(event.does_not_need_leaders?).to be_falsey
      event.registrations << reg_leader1
      expect(event.does_not_need_leaders?).to be_falsey
      event.registrations << reg_leader2
      expect(event.does_not_need_leaders?).to eq true
      event.registrations << reg_leader3
      expect(event.does_not_need_leaders?).to eq true
    end
  end

  describe '#format_date_only' do
    context 'when event is contained within a day' do
      it 'returns the start time with a format' do
        expect(event.format_date_only).to eq event.start_time.strftime('%a, %-m/%-d')
      end
    end

    context 'when event spans more than one day' do
      let(:real_long_event) { build :event, start_time: Time.now, end_time: Time.now + 2.days }
      it 'returns a formatted start and end time' do
        expect(real_long_event.format_date_only).to include ' to '
      end
    end
  end

  describe '#format_date_w_year' do
    context 'when event is contained within a day' do
      it 'returns the start time with a format' do
        expect(event.format_date_w_year).to eq event.start_time.strftime('%a, %-m/%-d/%y')
      end
    end

    context 'when event spans more than one day' do
      let(:real_long_event) { build :event, start_time: Time.now, end_time: Time.now + 2.days }
      it 'returns a formatted start and end time' do
        expect(real_long_event.format_date_w_year).to include ' to '
      end
    end
  end

  describe '#format_time_range' do
    context 'when event is contained within a day' do
      it 'returns the start and end times separated by a dash' do
        expect(event.format_time_range).to include ' - '
      end
    end

    context 'when event spans more than one day' do
      let(:real_long_event) { build :event, start_time: Time.now, end_time: Time.now + 2.days }
      it 'returns the start and end datetimes separated by "to"' do
        expect(real_long_event.format_time_range).to include ' to '
      end
    end
  end

  describe '#format_time_only' do
    context 'when event spans more than one day' do
      let(:real_long_event) { build :event, start_time: Time.now, end_time: Time.now + 2.days }

      it 'returns a string with a space' do
        expect(real_long_event.format_time_only).to eq ' '
      end
    end

    it 'returns the start and end times separated by a dash' do
      expect(event.format_time_only).to include ' - '
    end
  end

  describe '#format_time_slim' do
    it 'returns a string with the start and end times separated by a dash' do
      expect(event.format_time_slim).to include '-'
    end
  end

  describe '#full_title' do
    it 'returns a string with the start_time' do
      expect(event.full_title).to include event.start_time.strftime('%-m/%-d')
    end
  end

  describe '#full_title_w_year' do
    it 'returns a string with the start_time' do
      expect(event.full_title_w_year).to include event.start_time.strftime('%-m/%-d/%y')
    end
  end

  describe '#has_begun?' do
    let(:recent_event) { build :recent_event }
    let(:current_event) { build :event, start_time: Time.now - 10.minutes }

    it 'returns a boolean comparison of start_time to current time' do
      expect(event.has_begun?).to eq false
      expect(recent_event.has_begun?).to eq true
      expect(current_event.has_begun?).to eq true
    end
  end

  describe '#has_inventory?' do
    it 'returns inventory.present?' do
      expect(event.has_inventory?).to eq event.inventory.present?
    end
  end

  describe '#incomplete?' do
    it 'is the inverse of complete?' do
      expect(event.incomplete?).to eq !event.complete?
    end
  end

  describe '#in_the_future?' do
    let(:recent_event) { build :recent_event }
    let(:current_event) { build :event, start_time: Time.now - 10.minutes }

    it 'returns a boolean comparison of start_time to current time' do
      event.save
      event.reload

      expect(event.in_the_future?).to eq true
      expect(recent_event.in_the_future?).to eq false
      expect(current_event.in_the_future?).to eq false
    end
  end

  describe '#in_the_past?' do
    let(:recent_event) { create :recent_event }
    let(:current_event) { create :event, start_time: Time.now - 10.minutes }

    it 'returns a boolean comparison of end_time to current time' do
      event.save
      event.reload

      expect(event.in_the_past?).to eq false
      expect(recent_event.in_the_past?).to eq true
      expect(current_event.in_the_past?).to eq false
    end
  end

  describe '#leaders_have_vs_needed' do
    it 'returns a string' do
      expect(event.leaders_have_vs_needed.class).to eq String
    end
  end

  describe '#leaders_names' do
    it 'returns the names of registered leaders as a string' do
      reg_leader1.save
      reg_leader2.save

      expect(event.leaders_names).to eq "#{reg_leader1.user.fname}, #{reg_leader2.user.fname}"
    end
  end

  describe '#leaders_names_full' do
    it 'returns the names of registered leaders as a string' do
      reg_leader1.save
      reg_leader2.save

      expect(event.leaders_names_full).to eq "#{reg_leader1.user.name}, #{reg_leader2.user.name}"
    end
  end

  describe '#leaders_registered' do
    it 'returns the records of the registered active leaders' do
      reg_leader1.save
      reg_leader2.save

      expect(event.leaders_registered).to eq event.registrations.kept.leaders
    end
  end

  describe '#leaders_hours' do
    let(:reg_leader_a) { create :registration_leader_attended, event: complete_event }
    let(:reg_leader_b) { create :registration_leader_attended, event: complete_event }
    let(:reg_leader_c) { create :registration_leader_attended, event: complete_event }

    it 'returns the event hours * number of leaders' do
      reg_leader_a
      reg_leader_b
      reg_leader_c

      expect(complete_event.leaders_hours).to eq(3 * complete_event.length)
    end
  end

  describe '#length' do
    it 'returns the event duration in hours' do
      expect(event.length).to eq((event.end_time - event.start_time) / 1.hour)
    end
  end

  describe '#mailer_time' do
    it 'returns a formatted start_time' do
      expect(event.mailer_time).to eq event.start_time.strftime('%a, %-m/%-d')
    end
  end

  describe '#needs_leaders?' do
    it 'returns a boolean comparison of the number of leaders needed vs registered' do
      expect(event.needs_leaders?).to eq true

      reg_leader1.save
      expect(event.needs_leaders?).to eq true

      reg_leader2.save
      reg_leader3.save
      expect(event.needs_leaders?).to eq false
    end
  end

  describe '#needs_report?' do
    it 'returns a boolean response to attendance.zero?' do
      expect(event.needs_report?).to eq event.attendance.zero?
    end
  end

  describe '#number_of_builders_attended' do
    it 'returns the number of builders who attended' do
      reg_leader1.save
      reg_leader2.save
      reg1.save
      reg2.save

      event.attendance = (reg1.total_registered + reg2.total_registered + reg_leader1.total_registered + reg_leader2.total_registered)

      event.save

      expect(event.number_of_builders_attended).to eq(event.attendance - event.number_of_leaders_attended)
    end
  end

  describe '#number_of_leaders_attended' do
    it 'returns the number of leaders who attended' do
      reg_leader1.attended = true
      reg_leader1.save
      reg_leader2.attended = true
      reg_leader2.save

      expect(event.number_of_leaders_attended).to eq 2
    end
  end

  describe '#number_of_leaders_registered' do
    it 'returns the number of leaders registered' do
      reg_leader1.save
      reg_leader2.save

      expect(event.number_of_leaders_registered).to eq 2
    end
  end

  describe '#privacy_humanize' do
    context 'when event is private' do
      it 'returns a specific string' do
        event.is_private = true
        event.save

        expect(event.privacy_humanize).to eq 'Private Event'
      end
    end

    context 'when event is public' do
      it 'returns a specific string' do
        expect(event.privacy_humanize).to eq 'Public Event'
      end
    end
  end

  describe '#really_needs_leaders?' do
    let(:event2) { create :event, min_leaders: 2, max_leaders: 3 }

    it 'returns true if there are less leaders registered than the min' do
      expect(event2.really_needs_leaders?).to eq true
      event2.registrations << reg_leader1
      expect(event2.really_needs_leaders?).to eq true
      event2.registrations << reg_leader2
      expect(event2.really_needs_leaders?).to be_falsey
      event2.registrations << reg_leader3
      expect(event2.really_needs_leaders?).to be_falsey
    end
  end

  describe '#registrations_filled?' do
    it 'returns true when the count of total_registered >= max_registrations' do
      event.registrations << reg1
      event.registrations << reg2
      expect(event.registrations_filled?).to eq true
    end

    it 'returns false when the count of total_registered < max_registrations' do
      event.registrations << reg1
      expect(event.registrations_filled?).to be_falsey
    end
  end

  describe '#registrations_remaining' do
    it 'returns the # of slots remaining for the event' do
      expect(event.registrations_remaining).to eq(30)
      event.registrations << reg1
      expect(event.registrations_remaining).to eq(10)
      event.registrations << reg2
      expect(event.registrations_remaining).to eq(0)
    end
  end

  describe '#registrations_remaining_without(registration)' do
    it 'returns the # of slots remaining for the event excluding the given registration' do
      expect(event.registrations_remaining).to eq(30)
      event.registrations << reg1
      expect(event.registrations_remaining).to eq(10)
      expect(event.registrations_remaining_without(reg1.reload)).to eq(30)
      event.registrations << reg2
      expect(event.registrations_remaining).to eq(0)
      expect(event.registrations_remaining_without(reg2.reload)).to eq(10)
    end
  end

  describe '#registrations_would_overflow?(registration)' do
    let(:big_registration) { build :registration, guests_registered: 55, event: event }
    let(:little_registration) { build :registration, guests_registered: 1, event: event }

    it 'returns true if the given registration would bring the total registrations above the max_registrations limit' do
      expect(event.registrations_would_overflow?(big_registration)).to eq true

      expect(event.registrations_would_overflow?(little_registration)).to eq false
    end
  end

  describe '#results_people' do
    context 'when technology.people == 0' do
      let(:tech_no_ppl) { create :technology, people: 0 }
      let(:event2) { create :complete_event_technology, technology: tech_no_ppl }

      it 'returns 0' do
        expect(event2.results_people).to eq(0)
      end
    end

    context 'when event.technology_results == 0' do
      it 'returns 0' do
        expect(event.results_people).to eq(0)
      end
    end

    it 'returns the number of people served * technology_results' do
      expect(complete_event.results_people).to eq(300)
    end
  end

  describe '#results_timespan' do
    context 'when technology.lifespan_in_years == 0' do
      let(:tech_no_lifespan) { create :technology, lifespan_in_years: 0 }
      let(:event2) { create :complete_event_technology, technology: tech_no_lifespan }

      it 'returns 0' do
        expect(event2.results_timespan).to eq(0)
      end
    end

    context 'when event.technology_results == 0' do
      it 'returns 0' do
        expect(event.results_timespan).to eq(0)
      end
    end

    it 'returns the technology.lifespan_in_years' do
      expect(complete_event.results_timespan).to eq(10)
    end
  end

  describe '#results_liters_per_day' do
    context 'when technology.results_liters_per_day == 0' do
      let(:tech_no_liters) { create :technology, liters_per_day: 0 }
      let(:event2) { create :complete_event_technology, technology: tech_no_liters }

      it 'returns 0' do
        expect(event2.results_liters_per_day).to eq(0)
      end
    end

    context 'when event.technology_results == 0' do
      it 'returns 0' do
        expect(event.results_liters_per_day).to eq(0)
      end
    end

    it 'returns the liters per day * technology_results' do
      expect(complete_event.results_liters_per_day).to eq(6_000)
    end
  end

  describe '#results_liters_per_year' do
    it 'returns the results_liters_per_day * 365' do
      expect(complete_event.results_liters_per_year).to eq(complete_event.results_liters_per_day * 365)
    end
  end

  describe '#results_liters_lifespan' do
    it 'returns the results_liters_per_year * technology.lifespan_in_years' do
      expect(complete_event.results_liters_lifespan).to eq(complete_event.results_liters_per_year * complete_event.technology.lifespan_in_years)
    end
  end

  describe '#should_notify_admins?' do
    context 'when start_time_was is in the future and important_fields_for_admins_changed?' do
      it 'returns true' do
        complete_event.start_time = Time.now + 1.day
        expect(complete_event.should_notify_admins?).to eq false

        # event.start_time_was == 20 days in the future
        event.start_time = Time.now + 1.day
        expect(event.should_notify_admins?).to eq true
      end
    end
  end

  describe '#should_notify_builders_and_leaders?' do
    context 'when start_time_was is in the future and event has registrations and important_fields_for_admins_changed?' do
      it 'returns true' do
        complete_event.start_time = Time.now + 1.day
        expect(complete_event.should_notify_builders_and_leaders?).to eq false

        reg1.save
        # event.start_time_was == 20 days in the future
        event.start_time = Time.now + 1.day
        expect(event.should_notify_builders_and_leaders?).to eq true
      end
    end
  end

  describe '#should_create_inventory?' do
    context 'when inventory.present?' do
      let(:inventory) { create :inventory_event, event: completed_event }

      it 'returns false' do
        expect(complete_event.should_create_inventory?).to eq false
      end
    end

    context 'when inventory is not present and a meaningful value or change exists for technologies_built or boxes_packed' do
      let(:new_complete_event) { build :complete_event_technology }

      it 'returns true' do
        expect(new_complete_event.should_create_inventory?).to eq true
      end
    end
  end

  describe '#should_send_results_emails?' do
    context 'when emails_sent? is false, attendance is positive, registrations exist, technology_results are positive and technology is results_worthy' do
      let(:reg_comp_a) { create :registration_attended, event: complete_event }
      let(:reg_comp_b) { create :registration_attended, event: complete_event }
      let(:reg_comp_c) { create :registration_attended, event: complete_event_impact }
      let(:reg_comp_d) { create :registration_attended, event: complete_event_impact }

      it 'returns true' do
        reg_comp_a
        reg_comp_b
        reg_comp_c
        reg_comp_d

        expect(complete_event.should_send_results_emails?).to eq true
        expect(complete_event_impact.should_send_results_emails?).to eq true
      end
    end
  end

  describe '#technology_results' do
    context 'when event is incomplete' do
      it 'returns 0' do
        expect(event.incomplete?).to eq true

        expect(event.technology_results).to eq 0
      end
    end

    context 'when impact_results is greater than technologies completed' do
      it 'returns impact_results' do
        expect(complete_event_impact.technology_results).to eq complete_event_impact.impact_results
      end
    end

    context 'when technologies completed is greater than impact_results' do
      it 'returns technologies completed' do
        expect(complete_event.technology_results).to eq (complete_event.boxes_packed * complete_event.technology.quantity_per_box) + complete_event.technologies_built
      end
    end
  end

  describe '#total_registered' do
    it 'gives 0 when there are no registrations' do
      expect(event.registrations.kept.empty?).to eq true
      expect(event.total_registered).to eq(0)
    end

    it 'adds the number of guests and builders' do
      reg1.save
      reg2.save
      expect(event.total_registered).to eq(30)
    end
  end

  describe '#total_registered_w_leaders' do
    context 'when there are no active registrations' do
      it 'returns 0' do
        expect(event.registrations.kept.empty?).to eq true
        expect(event.total_registered_w_leaders).to eq 0
      end
    end

    context 'when there are active registrations' do
      it 'adds the number of guests and registrations' do
        reg1.save
        reg2.save
        reg_leader1.save
        reg_leader2.save

        expect(event.total_registered_w_leaders).to eq 32
      end
    end
  end

  describe '#total_registered_without(registration)' do
    context 'when there are no active registrations' do
      it 'returns 0' do
        expect(event.registrations.kept.empty?).to eq true
        expect(event.total_registered_without(reg2)).to eq 0
      end
    end

    context 'when there are active registrations' do
      it 'returns the number of guests_registered and registrations excluding the provided registration' do
        reg1.save
        reg2.save
        reg_leader1.save
        reg_leader2.save

        expect(event.registrations.kept.exists?).to eq true
        expect(event.total_registered_without(reg2)).to eq 22
      end
    end
  end

  describe 'volunteer_hours' do
    it 'multiplies event length by attendance' do
      expect(complete_event.volunteer_hours).to eq(complete_event.length * complete_event.attendance)
    end
  end

  describe '#you_are_attendee' do
    it 'checks to see if a user is registered as a non-leader' do
      expect(event.you_are_attendee(user)).to be_falsey

      reg1.save
      expect(event.you_are_attendee(user)).to eq ' (including you)'
    end
  end

  describe '#you_are_leader' do
    let(:leader) { create :leader }
    let(:reg3) { build :registration, user: user, event: event, leader: true }
    let(:reg4) { build :registration, user: leader, event: event, leader: true }

    it 'checks to see if a user is a leader and is registered as a leader' do
      expect(event.you_are_leader(leader)).to be_falsey

      event.registrations << reg3
      expect(event.you_are_leader(user)).to be_falsey

      event.registrations << reg4
      expect(event.you_are_leader(leader)).to eq ' (including you)'
    end
  end

  private

  describe '#dates_are_valid?' do
    let(:same_times) { build :event, start_time: Time.now, end_time: Time.now }
    let(:bad_times) { build :event, start_time: Time.now, end_time: Time.now - 3.hours }

    it 'must have start and end times' do
      expect(no_starttime.__send__(:dates_are_valid?)).to eq nil
      expect(no_endtime.__send__(:dates_are_valid?)).to eq nil
      expect(event.__send__(:dates_are_valid?)).to eq nil
    end

    it 'must have a start time that comes before end time' do
      same_times.save
      bad_times.save
      expect(same_times.errors.messages[:end_time]).to eq ['must be after start time']
      expect(bad_times.errors.messages[:end_time]).to eq ['must be after start time']
    end
  end

  describe '#important_fields_for_admins_changed?' do
    it 'returns true if ActiveRecor::Dirty calls return true on any of the specified fields' do
      event.start_time += 30.minutes
      expect(event.__send__(:important_fields_for_admins_changed?))

      event.reload.end_time += 1.hour
      expect(event.__send__(:important_fields_for_admins_changed?))

      event.reload.location = create :location
      expect(event.__send__(:important_fields_for_admins_changed?))

      event.reload.technology = create :technology
      expect(event.__send__(:important_fields_for_admins_changed?))

      event.reload.is_private = true
      expect(event.__send__(:important_fields_for_admins_changed?))
    end
  end

  describe '#important_fields_for_builders_changed?' do
    it 'returns true if ActiveRecor::Dirty calls return true on any of the specified fields' do
      event.start_time += 30.minutes
      expect(event.__send__(:important_fields_for_builders_changed?))

      event.reload.end_time += 1.hour
      expect(event.__send__(:important_fields_for_builders_changed?))

      event.reload.location = create :location
      expect(event.__send__(:important_fields_for_builders_changed?))
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
      expect(event.__send__(:leaders_are_valid?)).to eq nil
      expect(no_minleaders.__send__(:leaders_are_valid?)).to eq nil
      expect(no_maxleaders.__send__(:leaders_are_valid?)).to eq nil
    end

    it 'must have a min leader that is less than the max leader' do
      expect(same_leaders.__send__(:leaders_are_valid?)).to eq nil
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

  describe '#registrations_are_valid?' do
    let(:same_registrations) { build :event, min_registrations: 3, max_registrations: 3 }
    let(:less_registrations) { build :event, min_registrations: 23, max_registrations: 3 }

    let(:event2) { create :event }

    let(:reg3) { build :registration, event: event2, guests_registered: 10 }
    let(:reg4) { build :registration, event: event2, guests_registered: 10 }
    let(:reg5) { build :registration, event: event2, guests_registered: 10 }

    it 'must have min and max registrations' do
      expect(event.__send__(:registrations_are_valid?)).to eq nil
      expect(no_minleaders.__send__(:registrations_are_valid?)).to eq nil
      expect(no_maxleaders.__send__(:registrations_are_valid?)).to eq nil
    end

    it 'must have a min registration that is less than the max registrations' do
      expect(same_registrations.__send__(:registrations_are_valid?)).to eq nil
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
end
