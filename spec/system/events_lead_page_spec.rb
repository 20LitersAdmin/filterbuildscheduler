# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Events#lead' do
  context 'when visited by a' do
    it 'anon user, it redirects to sign-in page' do
      visit lead_events_path

      expect(page).to have_content 'You need to sign in first'
      expect(page).to have_content 'Sign in'
    end

    it 'builder, it redirects to home page' do
      sign_in create :user
      visit lead_events_path

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'leader, it shows the page' do
      sign_in create :leader
      visit lead_events_path

      expect(page).to have_content 'Builds that need leaders'
    end

    it 'inventoryist, it redirects to home page' do
      sign_in create :inventoryist
      visit lead_events_path

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'scheduler, it shows the page' do
      sign_in create :scheduler
      visit lead_events_path

      expect(page).to have_content 'Builds that need leaders'
    end

    it 'data_manager, it shows the page' do
      sign_in create :data_manager
      visit lead_events_path

      expect(page).to have_content 'Builds that need leaders'
    end

    it 'admin, it shows the page' do
      sign_in create :admin
      visit lead_events_path

      expect(page).to have_content 'Builds that need leaders'
    end
  end

  context 'with a collection of events' do
    let(:future_event_need_leaders) { create :event }

    let(:future_event) { create :event, max_leaders: 1 }
    let(:leader_reg) { create :registration_leader, event: future_event }

    let(:past_event) { create :past_event }

    it 'shows only future events needing leaders' do
      future_event_need_leaders
      leader_reg
      future_event
      past_event

      sign_in create :admin
      visit lead_events_path

      expect(page).to have_content future_event_need_leaders.title
      expect(page).not_to have_content future_event.title
      expect(page).not_to have_content past_event
    end
  end
end
