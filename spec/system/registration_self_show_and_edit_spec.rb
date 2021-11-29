# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Manage own registration:', type: :system do
  let(:event) { create :event }
  let(:user) { create :user, signed_waiver_on: Time.now }
  let(:registration) { create :registration, event: event, user: user }

  context 'anon user' do
    it "can't see a registration on the event page" do
      visit event_path event

      expect(page).to have_content event.full_title
      expect(page).to_not have_content "You're Registered!"
      expect(page).to_not have_link 'Change/Cancel Registration'
    end
  end

  context 'builder' do
    it 'can see their own registration on the event page' do
      registration
      sign_in user
      visit event_path event

      expect(page).to have_content event.full_title
      expect(page).to have_content user.name
      expect(page).to have_content "You're Registered"
      expect(page).to have_content 'Change/Cancel Registration'
    end

    it 'can edit their registration' do
      registration
      sign_in user
      visit event_path event

      expect(page).to have_content event.full_title
      click_link 'Change/Cancel Registration'

      expect(page).to have_content event.full_title
      expect(page).to have_content user.name
      expect(page).to have_field 'registration_guests_registered'
      expect(page).to have_field 'registration_accommodations'
      expect(page).to have_button 'Update'
      expect(page).to have_link 'Back'

      fill_in 'registration_guests_registered', with: '2'
      fill_in 'registration_accommodations', with: 'accepts edits'

      click_button 'Update'

      expect(page).to have_content event.full_title
      expect(page).to have_content "You're Registered"
      expect(page).to have_content 'Change/Cancel Registration'

      expect(registration.reload.guests_registered).to eq 2
      expect(registration.reload.accommodations).to eq 'accepts edits'
    end

    it 'can soft-delete their registration' do
      registration
      sign_in user
      visit event_path event

      expect(page).to have_content event.full_title
      click_link 'Change/Cancel Registration'

      expect(page).to have_link 'Cancel Registration'

      click_link 'Cancel Registration'

      expect(page).to have_content 'You are no longer registered.'
      expect(page).to have_content event.full_title
      expect(page).to have_content user.name
      expect(page).not_to have_content "You're Registered"

      expect(registration.reload.discarded_at).to_not be_nil
    end
  end

  fcontext 'leader of the event' do
    let(:user) { create :leader, signed_waiver_on: Time.now }

    let(:registration) { create :registration_leader, user: user, event: event }

    it 'can see their own registration which mentions they are a leader' do
      registration
      sign_in user
      visit event_path event

      expect(page).to have_content event.full_title
      expect(page).to have_content user.name
      expect(page).to have_content "You're Registered"
      expect(page).to have_content 'You are the only leader currently registered.'
    end

    it 'can edit their leader status via registration' do
      user.technologies << event.technology
      user.save

      registration
      sign_in user
      visit event_path event

      expect(page).to have_content event.full_title
      click_link 'Change/Cancel Registration'

      expect(page).to have_content event.full_title
      expect(page).to have_content user.name
      expect(page).to have_field 'registration_leader'
      expect(page).to have_button 'Update'

      find('input#registration_leader').uncheck

      click_button 'Update'

      expect(page).to have_content event.full_title
      expect(page).to have_content "You're Registered"
      expect(page).not_to have_content 'You are the only leader currently registered.'

      expect(registration.reload.leader).to eq false
    end
  end
end
