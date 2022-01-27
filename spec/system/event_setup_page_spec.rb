# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Events#Setup', type: :system do
  let(:events) { create_list :event, 3 }
  let(:past_event) { create :past_event }
  let(:setup_crew) { create :setup_crew }
  let(:setup) { create :setup, creator: setup_crew }

  context 'when visited by' do
    it 'anon users redirects to sign-in page' do
      visit setup_events_path

      expect(page).to have_content 'You need to sign in first'
      expect(page).to have_content 'Sign in'
    end

    it 'builders redirects to home page' do
      sign_in create(:user)

      visit setup_events_path

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'leaders shows the page' do
      sign_in create(:leader)

      visit setup_events_path
      expect(page).to have_content 'Upcoming Events for Setup'
    end

    it 'admins shows the page' do
      sign_in create(:admin)

      visit setup_events_path
      expect(page).to have_content 'Upcoming Events for Setup'
    end

    it 'inventoryist shows the page' do
      sign_in create(:inventoryist)

      visit setup_events_path

      expect(page).to have_content 'Upcoming Events for Setup'
    end

    it 'data managers shows the page' do
      sign_in create(:data_manager)

      visit setup_events_path
      expect(page).to have_content 'Upcoming Events for Setup'
    end

    it 'schedulers shows the page' do
      sign_in create(:scheduler)

      visit setup_events_path
      expect(page).to have_content 'Upcoming Events for Setup'
    end

    it 'setup crew shows the page' do
      sign_in setup_crew

      visit setup_events_path
      expect(page).to have_content 'Upcoming Events for Setup'
    end
  end

  it 'only shows future events' do
    sign_in setup_crew
    events
    past_event

    visit setup_events_path
    events.each do |event|
      expect(page).to have_content event.title
    end

    expect(page).not_to have_content past_event.title
  end

  it 'shows existing setups' do
    sign_in setup_crew
    events
    setup
    setup.event

    visit setup_events_path
    expect(page).to have_content setup.title
  end

  context 'when interacting as a user that can\'t manage other users (setup crew, inventoryist, leader), it allows for' do
    before do
      sign_in setup_crew
      events
      setup
      setup.event

      visit setup_events_path
    end

    context 'scheduling a new setup event' do
      it 'by clicking a Schedule button' do
        first('.setup-schedule').click

        expect(page).to have_content 'Pick a date and time to setup for this filter build:'
      end
    end

    context 'joining an existing setup event' do
      it 'by clicking a Join button' do
        expect(setup.users).not_to include setup_crew

        first('.setup-join').click

        expect(page).to have_content 'You are now registered to setup!'

        expect(setup.reload.users).to include setup_crew
      end
    end

    context 'cancelling from an existing setup event' do
      it 'by clicking a Cancel button' do
        setup.users.push(setup_crew)
        expect(setup.reload.users).to include setup_crew

        visit setup_events_path

        first('.setup-cancel').click

        expect(page).to have_content 'You cancelled this setup event.'
      end

      context 'when other setup crew are participating' do
        let(:second_crew) { create :setup_crew }

        it 'removes the setup crew from the users association' do
          setup.users.push(setup_crew, second_crew)
          expect(setup.reload.users.size).to eq 2

          visit setup_events_path

          first('.setup-cancel').click

          expect(page).to have_content 'You cancelled your registration for this setup.'

          expect(setup.reload.users).not_to include setup_crew
          expect(setup.users).to include second_crew
        end
      end

      context 'when no other setup crew are participating' do
        it 'destroys the setup event' do
          setup.users.push(setup_crew)
          expect(setup.reload.users).to include setup_crew

          visit setup_events_path

          expect { first('.setup-cancel').click }
            .to change { Setup.all.size }
            .by(-1)
        end
      end
    end
  end

  context 'interacting as a user that can manage users (admin, scheduler, data_manager)' do
    before do
      sign_in create(:admin)
      events
      setup
      setup.event

      visit setup_events_path
    end

    context 'editing an existing setup event' do
      it 'by clicking Edit button' do
        first('.setup-edit').click
        expect(page).to have_content 'Pick a date and time to setup for this filter build:'
      end
    end
  end
end
