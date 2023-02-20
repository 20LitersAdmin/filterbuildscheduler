# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Setup#New', type: :system do
  let(:setup_crew) { create :setup_crew }
  let(:event) { create :event }
  let(:setup) { build :setup, event:, creator: setup_crew }

  context 'when visited by' do
    it 'anon users redirects to sign-in page' do
      visit new_event_setup_path(event)

      expect(page).to have_content 'You need to sign in first'
      expect(page).to have_content 'Sign in'
    end

    it 'builders redirects to home page' do
      sign_in create(:user)

      visit new_event_setup_path(event)

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'leaders shows the page' do
      sign_in create(:leader)

      visit new_event_setup_path(event)
      expect(page).to have_content 'Pick a date and time to setup for this filter build:'
    end

    it 'admins shows the page' do
      sign_in create(:admin)

      visit new_event_setup_path(event)
      expect(page).to have_content 'Pick a date and time to setup for this filter build:'
      expect(page).to have_content 'Setup crew members attending:'
    end

    it 'inventoryist shows the page' do
      sign_in create(:inventoryist)

      visit new_event_setup_path(event)

      expect(page).to have_content 'Pick a date and time to setup for this filter build:'
    end

    it 'data managers shows the page' do
      sign_in create(:data_manager)

      visit new_event_setup_path(event)
      expect(page).to have_content 'Pick a date and time to setup for this filter build:'
      expect(page).to have_content 'Setup crew members attending:'
    end

    it 'schedulers shows the page' do
      sign_in create(:scheduler)

      visit new_event_setup_path(event)
      expect(page).to have_content 'Pick a date and time to setup for this filter build:'
      expect(page).to have_content 'Setup crew members attending:'
    end

    it 'setup crew shows the page' do
      sign_in setup_crew

      visit new_event_setup_path(event)
      expect(page).to have_content 'Pick a date and time to setup for this filter build:'
    end
  end

  context 'to create a new setup event' do
    before do
      sign_in setup_crew
      visit new_event_setup_path(event)
    end

    it 'fill out the form' do
      fill_in 'setup_date', with: setup.date
      click_submit

      expect(page).to have_content 'Setup event created.'
    end

    it 'requires a date' do
      fill_in 'setup_date', with: ''
      click_submit

      expect(page).to have_content 'can\'t be blank'
    end
  end
end
