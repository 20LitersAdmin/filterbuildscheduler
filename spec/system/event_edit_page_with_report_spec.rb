# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'To create an event report', type: :system do
  let(:event) { create :recent_event }

  context 'when visited by' do
    it 'anon users redirects to sign_in page' do
      visit edit_event_path event

      expect(page).to have_content 'You need to sign in first'
      expect(page).to have_content 'Sign in'
    end

    it 'builders redirects to home page' do
      sign_in create(:user)

      visit edit_event_path event

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'leaders shows the page' do
      sign_in create(:leader)

      visit edit_event_path event

      expect(page).to have_content event.title
      expect(page).to have_css 'form.edit_event'
    end

    it 'inventory users redirects to home page' do
      sign_in create(:inventoryist)
      visit edit_event_path event

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'admins shows the page' do
      sign_in create(:admin)
      visit edit_event_path event

      expect(page).to have_content event.title
      expect(page).to have_css 'form.edit_event'
    end

    it 'schedulers shows the page' do
      sign_in create(:scheduler)
      visit edit_event_path event

      expect(page).to have_content event.title
      expect(page).to have_css 'form.edit_event'
    end

    it 'data_managers shows the page' do
      sign_in create(:data_manager)
      visit edit_event_path event

      expect(page).to have_content event.title
      expect(page).to have_css 'form.edit_event'
    end
  end

  context 'by visiting the Event#edit page,' do
    before { sign_in create :admin }

    it 'future events don\'t include an event report section' do
      event = create(:event)
      visit edit_event_path event

      expect(page).to have_content event.title
      expect(page).to have_button 'Submit'

      expect(page).not_to have_field 'event_technologies_built'
      expect(page).not_to have_field 'event_boxes_packed'
      expect(page).not_to have_field 'event_attendance'
      expect(page).not_to have_content 'Registration-based attendance:'
    end

    it 'complete events still have an event report section' do
      completed_event = create(:complete_event_technology)
      visit edit_event_path completed_event

      expect(page).to have_content completed_event.title
      expect(page).to have_content 'Report'
      expect(page).to have_field 'event_technologies_built'
      expect(page).to have_field 'event_boxes_packed'
      expect(page).to have_field 'event_attendance'
      expect(page).to have_content 'Registration-based attendance:'
      expect(page).to have_button 'Submit'
    end

    it 'past events have an event report section' do
      recent_event = create(:recent_event)
      visit edit_event_path recent_event

      expect(page).to have_content recent_event.title
      expect(page).to have_content 'Report'
      expect(page).to have_field 'event_technologies_built'
      expect(page).to have_field 'event_boxes_packed'
      expect(page).to have_field 'event_attendance'
      expect(page).to have_content 'Registration-based attendance:'
      expect(page).to have_button 'Submit'

      # no registrations means no option to email results
      expect(page).not_to have_button 'Submit & Email Results'
    end

    context 'with registrations present' do
      let(:registrations) { create_list :registration, 2, event: event }

      it 'can email results' do
        registrations
        expect(event.registrations.size).to eq 2

        visit edit_event_path event

        expect(page).to have_button 'Submit & Email Results'
      end
    end

    context 'when the event is more than 14 days old' do
      let(:past_event) { create :past_event }
      let(:registrations) { create_list :registration, 2, event: past_event }

      it 'cannot email results' do
        registrations
        expect(past_event.registrations.size).to eq 2

        visit edit_event_path past_event

        expect(page).to have_button 'Submit'
        expect(page).not_to have_button 'Submit & Email Results'
      end
    end
  end

  context 'fill out the form' do
    before do
      create_list :registration, 5, event: event
      sign_in create :admin
      visit edit_event_path event
    end

    it 'with some technology stats', retry: 3 do
      fill_in 'event_technologies_built', with: 450
      fill_in 'event_boxes_packed', with: 4

      click_button 'Submit'

      expect(page).to have_content 'Event updated.'
      event.reload
      expect(event.technologies_built).to eq 450
      expect(event.boxes_packed).to eq 4
      expect(event.attendance).to eq 0
      expect(event.emails_sent).to be false
    end

    context 'with attendee information', js: true do
      it 'auto-counts the total attendance' do
        expect(page).to have_css('div.event_registrations_attended', count: 5)
        expect(page).to have_field('event_attendance', with: '0')

        check 'event_registrations_attributes_0_attended'

        expect(page).to have_field('event_attendance', with: '1')

        fill_in 'event_registrations_attributes_1_guests_attended', with: 2
        check 'event_registrations_attributes_1_attended'

        expect(page).to have_field('event_attendance', with: '4')

        uncheck 'event_registrations_attributes_0_attended'

        expect(page).to have_field('event_attendance', with: '3')
      end

      it ' allows for select-all / un-select all' do
        expect(page).to have_css('div.event_registrations_attended', count: 5)
        expect(page).to have_field('event_attendance', with: '0')

        click_link 'btn_check_all'

        expect(page).to have_field('event_attendance', with: '5')

        click_link 'btn_uncheck_all'

        expect(page).to have_field('event_attendance', with: '0')
      end
    end

    it 'and submit it without sending emails', js: true do
      fill_in 'event_technologies_built', with: 250
      fill_in 'event_boxes_packed', with: 2
      click_link 'btn_check_all'

      expect(page).to have_field('event_attendance', with: '5')

      expect { click_button 'Submit' }
        .not_to change { ActionMailer::Base.deliveries.count }

      expect(page).to have_content 'Event updated.'
      event.reload
      expect(event.complete?).to eq true
      expect(event.technologies_built).to eq 250
      expect(event.boxes_packed).to eq 2
      expect(event.emails_sent).to eq false

      # expect(ActionMailer::Base.deliveries.count).to eq 0
    end

    it 'and submit it while sending emails', js: true do
      fill_in 'event_technologies_built', with: 350
      fill_in 'event_boxes_packed', with: 3
      click_link 'btn_check_all'

      expect(page).to have_field('event_attendance', with: '5')

      expect { click_button 'Submit & Email Results' }
        .to have_enqueued_mail(RegistrationMailer, :event_results)
        .exactly(5).times

      expect(page).to have_content 'Event updated.'
      expect(page).to have_content 'Attendees notified of results.'
      event.reload

      expect(page).to have_content 'Event updated.'
      event.reload
      expect(event.complete?).to eq true
      expect(event.technologies_built).to eq 350
      expect(event.boxes_packed).to eq 3
      expect(event.emails_sent).to eq true
    end

    it 'and submit it to create an inventory' do
      allow(EventInventoryJob).to receive(:perform_later).with(event)

      fill_in 'event_technologies_built', with: 350
      fill_in 'event_boxes_packed', with: 3

      click_button 'Submit'

      expect(page).to have_content 'Event updated.'
      expect(page).to have_content 'Inventory created.'

      expect(EventInventoryJob).to have_received(:perform_later).with(event)
    end

    it 'and submit it to send registration information to Bloomerang', js: true do
      click_link 'btn_check_all'

      expect { click_button 'Submit' }
        .to have_enqueued_job.on_queue('bloomerang_job').exactly(5).times

      expect(page).to have_content 'Event updated.'
    end
  end
end
