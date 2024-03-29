# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin editing event registrations', type: :system do
  let(:user) { create :user }
  let(:event) { create :event }
  let(:registration) { create :registration, user:, event: }
  let(:admin) { create :admin }

  before do
    sign_in admin
    visit edit_event_registration_path event, registration, admin: true
  end

  context 'when event allows guests' do
    it 'can see the registration form' do
      expect(page).to have_content event.full_title
      expect(page).to have_content user.name

      expect(page).to have_field 'registration_user_email_opt_out'
      expect(page).to have_field 'registration_guests_registered'
      expect(page).to have_field 'registration_accommodations'
      expect(page).to have_button 'Update'
      expect(page).to have_link 'Cancel Registration'
      expect(page).to have_link 'Back'
    end

    it 'can fill out and update' do
      expect(page).to have_content event.full_title
      expect(page).to have_content user.name

      fill_in 'registration_guests_registered', with: 1
      check 'registration_user_email_opt_out'

      click_button 'Update'
      # get navigated to registrations#index

      # return to the form
      visit edit_event_registration_path event, registration, admin: true

      expect(page).to have_css "input#registration_guests_registered[value='1']"
      expect(page).to have_css 'input#registration_user_email_opt_out[checked=checked]'

      expect(user.reload.email_opt_out).to eq true
      expect(registration.reload.guests_registered).to eq 1
    end

    it 'can cancel (discarded)' do
      expect(page).to have_content event.full_title
      expect(page).to have_content user.name

      click_link 'Cancel Registration'

      expect(page).to have_content 'Registration discarded, but can be restored.'
      expect(page).to have_content 'Discarded registrations'
    end
  end

  context 'when event does not allow guests' do
    before do
      event.update(allow_guests: false)
      visit edit_event_registration_path event, registration, admin: true
    end

    it 'does not see guests_registered field' do
      expect(page).to have_content event.full_title
      expect(page).to have_content user.name
      expect(page).not_to have_field 'registration_guests_registered'
    end
  end
end
