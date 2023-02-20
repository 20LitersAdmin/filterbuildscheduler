# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create events:', type: :system do
  context 'anon user' do
    it 'can\'t visit the new event page' do
      visit new_event_path

      expect(page).to have_content 'You need to sign in first'
      expect(page).to have_content 'Sign in'
    end
  end

  context 'builder' do
    let(:builder) { create :user }

    it 'can\'t visit the new event page' do
      sign_in builder
      visit new_event_path

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end
  end

  context 'leader' do
    let(:leader) { create :leader }

    it 'can visit the new event page' do
      sign_in leader
      visit new_event_path

      expect(page).to have_field 'event_title'
      expect(page).to have_field 'event_location_id'
      expect(page).to have_field 'event_is_private'
      expect(page).to have_button 'Submit'
      expect(page).to have_link 'Back'
    end
  end

  context 'inventoryist' do
    let(:inventoryist) { create :inventoryist }

    it 'can\'t visit the new event page' do
      sign_in inventoryist
      visit new_event_path

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end
  end

  context 'scheduler' do
    let(:scheduler) { create :scheduler }

    it 'can visit the new event page' do
      sign_in scheduler
      visit new_event_path

      expect(page).to have_field 'event_title'
      expect(page).to have_field 'event_location_id'
      expect(page).to have_field 'event_is_private'
      expect(page).to have_button 'Submit'
      expect(page).to have_link 'Back'
    end
  end

  context 'data manager' do
    let(:data_manager) { create :data_manager }

    it 'can visit the new event page' do
      sign_in data_manager
      visit new_event_path

      expect(page).to have_field 'event_title'
      expect(page).to have_field 'event_location_id'
      expect(page).to have_field 'event_is_private'
      expect(page).to have_button 'Submit'
      expect(page).to have_link 'Back'
    end
  end

  context 'admin' do
    before :each do
      @user = create(:admin, send_event_emails: true)
      @location = create(:location)
      @technology = create(:technology)
      sign_in @user
      visit new_event_path
    end

    it 'can visit the new event page' do
      expect(page).to have_field 'event_title'
      expect(page).to have_field 'event_location_id'
      expect(page).to have_field 'event_is_private'
      expect(page).to have_button 'Submit'
      expect(page).to have_link 'Back'
    end
  end

  context 'by filling out the form' do
    let(:admin) { create :admin }
    let(:location) { create :location }
    let(:technology) { create :technology }
    let(:event) { build :event, location:, technology: }

    it 'creates the event and sends an email' do
      location
      technology
      sign_in admin
      visit new_event_path

      fill_in 'event_title', with: event.title
      find('#event_location_id').find(:css, "option[value=#{location.id}]").select_option
      fill_in 'event_start_time', with: event.start_time
      fill_in 'event_end_time', with: event.end_time
      fill_in 'event_description', with: 'Capybara did this'
      find('#event_technology_id').find(:css, "option[value=#{technology.id}]").select_option
      fill_in 'event_min_leaders', with: event.min_leaders
      fill_in 'event_max_leaders', with: event.max_leaders
      fill_in 'event_min_registrations', with: event.min_registrations
      fill_in 'event_max_registrations', with: event.max_registrations

      expect { click_button 'Submit' }
        .to have_enqueued_mail

      expect(page).to have_content 'Upcoming Builds'

      saved_event = Event.last
      expect(saved_event.title).to eq event.title
      expect(saved_event.location).to eq event.location
      expect(saved_event.technology).to eq event.technology
    end
  end
end
