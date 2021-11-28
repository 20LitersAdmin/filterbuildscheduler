# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create :user }

  describe 'must be valid' do
    let(:good_user) { build :user }
    let(:blank_password) { build :user }
    let(:no_fname) { build :user, fname: nil }
    let(:no_lname) { build :user, lname: nil }
    let(:no_email) { build :user, email: nil }

    it 'in order to save' do
      expect(good_user.save).to eq true
      expect(blank_password.save).to eq true
      expect(no_fname.save).to eq false
      expect(no_lname.save).to eq false
      expect(no_email.save).to eq false
    end
  end

  describe '#admin_or_leader?' do
    context 'when user is' do
      let(:admin_user) { build :admin }
      let(:leader_user) { build :leader }
      let(:inventory_user) { build :inventoryist }
      let(:scheduler_user) { build :scheduler }
      let(:data_manager_user) { build :data_manager }

      it 'admin, returns true' do
        expect(admin_user.admin_or_leader?).to eq true
      end

      it 'leader, returns true' do
        expect(leader_user.admin_or_leader?).to eq true
      end

      it 'inventoryist, returns true' do
        expect(inventory_user.admin_or_leader?).to eq true
      end

      it 'scheduler, returns true' do
        expect(scheduler_user.admin_or_leader?).to eq true
      end

      it 'data_manager, returns true' do
        expect(data_manager_user.admin_or_leader?).to eq true
      end

      it 'builder, returns false' do
        expect(user.admin_or_leader?).to eq false
      end
    end
  end

  describe '#availability' do
    context 'when not a leader' do
      it 'returns nil' do
        expect(user.availability).to eq nil
      end
    end

    context 'when a leader' do
      let(:leader) { build :leader }

      context 'and available_business_hours is true' do
        context 'and available_after_hours is false' do
          it 'returns Business hours' do
            leader.available_business_hours = true
            leader.available_after_hours = false

            expect(leader.availability).to eq 'Business hours'
          end
        end

        context 'and available_after_hours is true' do
          it 'returns All hours' do
            leader.available_business_hours = true
            leader.available_after_hours = true

            expect(leader.availability).to eq 'All hours'
          end
        end
      end

      context 'and available_business_hours is false' do
        context 'and available_after_hours is true' do
          it 'returns After hours' do
            leader.available_business_hours = false
            leader.available_after_hours = true

            expect(leader.availability).to eq 'After hours'
          end
        end

        context 'and available_after_hours is false' do
          it 'returns Unknown' do
            leader.available_business_hours = false
            leader.available_after_hours = false

            expect(leader.availability).to eq 'Unknown'
          end
        end
      end
    end
  end

  describe '#availability_code' do
    context 'when not a leader' do
      it 'returns nil' do
        expect(user.availability_code).to eq nil
      end
    end

    context 'when a leader' do
      let(:leader) { build :leader }

      context 'and available_business_hours is true' do
        context 'and available_after_hours is false' do
          it 'returns 1' do
            leader.available_business_hours = true
            leader.available_after_hours = false

            expect(leader.availability_code).to eq 1
          end
        end

        context 'and available_after_hours is true' do
          it 'returns 0' do
            leader.available_business_hours = true
            leader.available_after_hours = true

            expect(leader.availability_code).to eq 0
          end
        end
      end

      context 'and available_business_hours is false' do
        context 'and available_after_hours is true' do
          it 'returns 2' do
            leader.available_business_hours = false
            leader.available_after_hours = true

            expect(leader.availability_code).to eq 2
          end
        end

        context 'and available_after_hours is false' do
          it 'returns nil' do
            leader.available_business_hours = false
            leader.available_after_hours = false

            expect(leader.availability_code).to eq nil
          end
        end
      end
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

      expect(user.available_events.count).to eq(2)
    end

    it 'shows all events I have registered for' do
      Registration.create user: user, event: private_event

      expect(user.available_events).to eq([private_event])
    end

    it 'shows all public events and all events I have registered for' do
      event1
      event2
      Registration.create user: user, event: private_event

      expect(user.available_events).to include(event1)
      expect(user.available_events).to include(event2)
      expect(user.available_events).to include(private_event)
    end
  end

  describe '#can_do_inventory?' do
    context 'when user is' do
      let(:admin_user) { build :admin }
      let(:inventory_user) { build :inventoryist }
      let(:data_manager) { build :data_manager }

      it 'admin, returns true' do
        expect(admin_user.can_do_inventory?).to eq true
      end

      it 'inventoryist, returns true' do
        expect(inventory_user.can_do_inventory?).to eq true
      end

      it 'data_manager, returns true' do
        expect(data_manager.can_do_inventory?).to eq true
      end
    end

    context 'when user is not admin or inventoryist' do
      it 'returns false' do
        user.is_oauth_admin = true
        user.is_leader = true
        user.is_scheduler = true
        user.send_notification_emails = true
        user.send_inventory_emails = true

        expect(user.can_do_inventory?).to eq false
      end
    end
  end

  describe '#can_view_inventory?' do
    context 'when user' do
      let(:admin_user) { build :admin }
      let(:inv_user) { build :user, send_inventory_emails: true }

      it 'can_do_inventory, returns true' do
        expect(admin_user.can_view_inventory?).to eq true
      end

      it 'receives inventory emails, returns true' do
        expect(inv_user.can_view_inventory?).to eq true
      end
    end

    context 'when user cannot do inventory or receive inventory emails' do
      it 'returns false' do
        user.is_oauth_admin = true
        user.is_leader = true
        user.is_scheduler = true
        user.send_notification_emails = true

        expect(user.can_do_inventory?).to eq false
      end
    end
  end

  describe '#can_edit_events?' do
    let(:admin_user) { build :admin }
    let(:leader_user) { build :leader }
    let(:scheduler_user) { build :scheduler }
    let(:data_manager_user) { build :data_manager }

    context 'when user is' do
      it 'admin, returns true' do
        expect(admin_user.can_edit_events?).to eq true
      end

      it 'leader, returns true' do
        expect(leader_user.can_edit_events?).to eq true
      end

      it 'scheduler, returns true' do
        expect(scheduler_user.can_edit_events?).to eq true
      end

      it 'data manager, returns true' do
        expect(data_manager_user.can_edit_events?).to eq true
      end
    end

    context 'when user is not admin, leader, scheduler or data manager' do
      it 'returns false' do
        user.is_oauth_admin = true
        user.does_inventory = true
        user.send_notification_emails = true
        user.send_inventory_emails = true

        expect(user.can_edit_events?).to eq false
      end
    end
  end

  describe '#can_manage_leaders?' do
    let(:admin_user) { build :admin }
    let(:leader_user) { build :leader }
    let(:inventory_user) { build :inventoryist }
    let(:scheduler_user) { build :scheduler }
    let(:data_manager_user) { build :data_manager }

    context 'when user is' do
      it 'admin, returns true' do
        expect(admin_user.can_manage_leaders?).to eq true
      end

      it 'scheduler, returns true' do
        expect(scheduler_user.can_manage_leaders?).to eq true
      end
    end

    context 'when user is not admin or scheduler' do
      it 'returns false' do
        user.is_oauth_admin = true
        user.is_leader = true
        user.does_inventory = true
        user.is_data_manager = true
        user.send_notification_emails = true
        user.send_inventory_emails = true

        expect(user.can_manage_leaders?).to eq false
      end
    end
  end

  describe '#can_lead_event?(event)' do
    let(:event) { create :event }
    let(:qualified) { create :leader }
    let(:unqualified) { create :user }

    it 'can lead an event when the join table has a record' do
      qualified.technologies << event.technology
      expect(qualified.technologies.exists?(event.technology.id)).to be_truthy
      expect(qualified.can_lead_event?(event)).to be_truthy
      expect(unqualified.technologies.exists?(event.technology.id)).to be_falsey
      expect(unqualified.can_lead_event?(event)).to be_falsey
    end

    it 'can\'t lead an event if they aren\'t a leader' do
      qualified.technologies << event.technology
      expect(qualified.is_leader).to be_truthy
      expect(qualified.can_lead_event?(event)).to be_truthy
      expect(unqualified.is_leader).to be_falsey
      expect(unqualified.can_lead_event?(event)).to be_falsey
    end
  end

  describe '#email_domain' do
    it 'returns the domain of the email' do
      user.email = 'chip@20liters.org'
      expect(user.email_domain).to eq '@20liters'
    end
  end

  describe '#email_opt_in' do
    it 'is the inverse of email_opt_out' do
      expect(user.email_opt_out).to eq false
      expect(user.email_opt_in).to eq true

      user.email_opt_out = true

      expect(user.email_opt_out).to eq true
      expect(user.email_opt_in).to eq false
    end
  end

  describe '#events_attended' do
    let(:event_attended) { create :past_event }
    let(:registration_attended) { create :registration_attended, user: user, event: event_attended }

    let(:event_unattended) { create :past_event }

    let(:registration_unattended) { create :registration_attended, event: event_unattended }

    let(:event_registered) { create :past_event }
    let(:registration_registered) { create :registration, event: event_registered, user: user }

    let(:event_future) { create :event }
    let(:registration_future) { create :registration, user: user }

    it 'returns a collection of past events based upon registrations.attended' do
      registration_attended
      registration_unattended
      registration_future

      expect(user.events_attended).to include event_attended
      expect(user.events_attended).not_to include event_unattended
      expect(user.events_attended).not_to include event_registered
      expect(user.events_attended).not_to include event_future
    end
  end

  describe '#events_led' do
    context 'when user is_leader' do
      let(:leader) { create :leader }
      let(:event_attended) { create :past_event }
      let(:registration_attended) { create :registration_leader_attended, user: leader, event: event_attended }

      let(:event_unattended) { create :past_event }

      let(:registration_unattended) { create :registration_leader_attended, event: event_unattended }

      let(:event_registered) { create :past_event }
      let(:registration_registered) { create :registration_leader, event: event_registered, user: leader }

      let(:event_future) { create :event }
      let(:registration_future) { create :registration, user: leader }

      it 'returns a collection of past events based upon registrations.attended.leaders' do
        registration_attended
        registration_unattended
        registration_future

        expect(leader.events_led).to include event_attended
        expect(leader.events_led).not_to include event_unattended
        expect(leader.events_led).not_to include event_registered
        expect(leader.events_led).not_to include event_future
      end
    end

    context 'when user is not leader' do
      it 'returns Event.none' do
        expect(user.events_led).to eq Event.none
      end
    end
  end

  describe '#events_skipped' do
    let(:event_attended) { create :past_event }
    let(:registration_attended) { create :registration_attended, user: user, event: event_attended }

    let(:event_unregistered) { create :past_event }
    let(:registration_unregistered) { create :registration, event: event_unregistered }

    let(:event_registered) { create :past_event }
    let(:registration_registered) { create :registration, event: event_registered, user: user }

    let(:event_future) { create :event }
    let(:registration_future) { create :registration, user: user, event: event_future }

    it 'returns a collection of past events based upon registrations.where(attended: false)' do
      registration_attended
      registration_unregistered
      registration_registered
      registration_future

      expect(user.events_skipped).not_to include event_attended
      expect(user.events_skipped).not_to include event_unregistered
      expect(user.events_skipped).to include event_registered
      expect(user.events_skipped).not_to include event_future
    end
  end

  describe '#has_no_password' do
    context 'when encrypted password is present' do
      let(:user_w_password) { create :user_w_password }

      it 'returns false' do
        expect(user_w_password.has_no_password).to eq false
      end
    end

    context 'when encrypted password is not present' do
      it 'returns true' do
        expect(user.has_no_password).to eq true
      end
    end
  end

  describe '#has_password' do
    context 'when encrypted password is present' do
      let(:user_w_password) { create :user_w_password }

      it 'returns true' do
        expect(user_w_password.has_password).to eq true
      end
    end

    context 'when encrypted password is not present' do
      it 'returns false' do
        expect(user.has_password).to eq false
      end
    end
  end

  describe '#leading?(event)' do
    let(:event) { create :event }
    let(:leader) { create :leader }

    context 'when user is not a leader' do
      it 'returns false' do
        expect(user.leading?(event)).to eq false
      end
    end

    context 'when the leader is registered to lead the given event' do
      let(:registration) { create :registration_leader, user: leader, event: event }

      it 'returns true' do
        registration

        expect(leader.leading?(event)).to eq true
      end
    end

    context 'when the leader is not registered to lead the given event' do
      let(:registration) { create :registration_leader, event: event }
      it 'returns false' do
        expect(leader.leading?(event)).to eq false
      end
    end
  end

  describe '#name' do
    it 'concatentates fname and lname' do
      expect(user.name).to eq("#{user.fname} #{user.lname}")
    end
  end

  describe '#registered?(event)' do
    let(:event) { create :event }
    let(:user) { create :user }

    context 'when the user is registered for the given event' do
      let(:registration) { create :registration, user: user, event: event }

      it 'returns true' do
        registration

        expect(user.registered?(event)).to eq true
      end
    end

    context 'when the user is not registered for the given event' do
      let(:registration) { create :registration, event: event }

      it 'returns false' do
        expect(user.registered?(event)).to eq false
      end
    end
  end

  describe '#total_volunteer_hours' do
    it 'returns a float of the length of all events attended' do
      3.times do
        # FactoryBot events are 3 hours in length
        event = create :past_event
        create :registration_attended, event: event, user: user
      end

      expect(user.total_volunteer_hours).to eq 9.0
    end
  end

  describe '#total_leader_hours' do
    before do
      @leader = create :leader
      3.times do
        # FactoryBot events are 3 hours in length
        event = create :past_event
        create :registration_attended, event: event, user: user
        create :registration_leader_attended, event: event, user: @leader
      end
    end

    context 'when user is_leader' do
      it 'returns a float of the length of all events led' do
        expect(@leader.total_leader_hours).to eq 9
      end
    end

    context 'when user is not a leader' do
      it 'returns 0' do
        expect(user.total_leader_hours).to eq 0
      end
    end
  end

  describe '#total_guests' do
    it 'returns an integer of the sum of all registrations#guests_attended' do
      3.times do
        # FactoryBot events are 3 hours in length
        event = create :past_event
        create :registration_attended, event: event, user: user, guests_attended: 5
      end

      expect(user.total_guests).to eq 15
    end
  end

  describe '#techs_qualified' do
    context 'when user is not a leader' do
      it 'returns nil' do
        expect(user.techs_qualified).to eq nil
      end
    end

    context 'when user is a leader' do
      let(:leader) { create :leader }

      context 'but has no technologies' do
        it 'returns nil' do
          expect(leader.techs_qualified).to eq nil
        end
      end

      context 'with associated technologies' do
        it 'returns an array of tech names and owners' do
          3.times do
            tech = create(:technology)
            leader.technologies << tech
          end

          Technology.all.each do |tech|
            expect(leader.techs_qualified).to include "#{tech.name} (#{tech.owner})"
          end
        end
      end
    end
  end

  describe '#techs_qualified_html' do
    context 'when user is not a leader' do
      it 'returns nil' do
        expect(user.techs_qualified_html).to eq nil
      end
    end

    context 'when user is a leader' do
      let(:leader) { create :leader }

      context 'but has no technologies' do
        it 'returns nil' do
          expect(leader.techs_qualified_html).to eq nil
        end
      end

      context 'with associated technologies' do
        before do
          3.times do
            tech = create :technology
            leader.technologies << tech
          end
        end

        it 'returns an array of tech names and owners' do
          Technology.all.each do |tech|
            expect(leader.techs_qualified_html).to include "<li>#{tech.name} (#{tech.owner})</li>"
          end
        end

        it 'calls :html_safe' do
          expect_any_instance_of(String).to receive(:html_safe)

          leader.techs_qualified_html
        end
      end
    end
  end

  private

  describe '#ensure_authentication_token' do
    it 'fires on before_save' do
      expect(user).to receive(:ensure_authentication_token)
      user.save
    end

    context 'when authentication_token is present' do
      it 'does nothing' do
        expect(user.authentication_token.present?).to eq true
        expect(user).not_to receive(:generate_authentication_token)
        user.save
      end
    end
    context 'when authentication_token is blank' do
      it 'sets a new token' do
        allow(user).to receive(:generate_authentication_token).and_call_original

        user.authentication_token = nil
        expect(user).to receive(:generate_authentication_token)
        user.save
        expect(user.reload.authentication_token.present?).to eq true
      end
    end
  end

  describe '#check_phone_format' do
    let(:good_phone) { build :user, phone: '(616) 555-1212' }
    let(:bad_phone) { build :user, phone: '(616;) 555=1212&$$$' }
    let(:text_phone) { build :user, phone: 'DELETE BobbyTables!;' }

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

  describe '#generate_authentication_token' do
    it 'assigns a unique Devise.friendly_token' do
      user.authentication_token = nil

      expect(user.authentication_token).to eq nil
      user.__send__(:ensure_authentication_token)
      expect(user.authentication_token).not_to eq nil
    end

    it 'calls Devise.friendly_token' do
      allow(Devise).to receive(:friendly_token).and_call_original

      expect(Devise).to receive(:friendly_token)

      user.__send__(:generate_authentication_token)
    end
  end

  describe '#update_kindful' do
    let(:user2) { build :user }
    context 'when name, email, opt_out or phone have changed' do
      it 'fires on after_save' do
        expect(user2).to receive(:update_kindful)
        user2.save

        user.fname = 'New'
        expect(user).to receive(:update_kindful)
        user.save

        user.email = 'new@email.comb'
        expect(user).to receive(:update_kindful)
        user.save

        user.email_opt_out = true
        expect(user).to receive(:update_kindful)
        user.save

        user.phone = '123-456-7891'
        expect(user).to receive(:update_kindful)
        user.save
      end

      it 'takes user data and sends it to kindful_client' do
        expect_any_instance_of(KindfulClient).to receive(:import_user).with(user2)
        user2.save
      end
    end

    context 'when name, email, opt_out and phone have not changed' do
      it 'doesn\'t fire' do
        expect(user).not_to receive(:update_kindful)

        user.is_leader = true
        user.signed_waiver_on = Date.today
        user.leader_notes = 'New note'

        user.save
      end
    end
  end
end
