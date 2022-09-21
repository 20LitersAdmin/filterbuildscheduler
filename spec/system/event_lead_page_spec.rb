# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Events#Lead', type: :system do
  let(:events) { create_list :event, 3 }

  context 'when visited by' do
    it 'anon users redirects to sign-in page' do
      visit lead_events_path

      expect(page).to have_content 'You need to sign in first'
      expect(page).to have_content 'Sign in'
    end

    it 'builders redirects to home page' do
      sign_in create(:user)

      visit lead_events_path

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'leaders shows the page' do
      sign_in create(:leader)

      visit lead_events_path
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'admins shows the page' do
      sign_in create(:admin)

      visit lead_events_path
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'inventoryist redirects to home page' do
      sign_in create(:inventoryist)

      visit lead_events_path

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'data managers shows the page' do
      sign_in create(:data_manager)

      visit lead_events_path
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'schedulers shows the page' do
      sign_in create(:scheduler)

      visit lead_events_path
      expect(page).to have_content 'Upcoming Builds'
    end
  end

  it 'shows all future events' do
    events
    event4 = create(:past_event, title: 'PAST EVENT')
    create(:registration_leader, event: event4)

    sign_in create(:leader)

    visit lead_events_path

    expect(page).to have_content events.first.title
    expect(page).to have_content events.second.title
    expect(page).to have_content events.third.title
    expect(page).not_to have_content event4.title
  end
end
