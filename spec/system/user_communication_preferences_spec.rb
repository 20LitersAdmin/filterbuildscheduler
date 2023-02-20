# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Users#communication page', type: :system do
  context 'when visited by' do
    it 'anon users redirects to sign-in page' do
      visit users_communication_path

      expect(page).to have_content 'You need to sign in first'
      expect(page).to have_content 'Sign in'
    end

    it 'builders redirects to home page' do
      sign_in create(:user)

      visit users_communication_path

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'leaders redirects to home page' do
      sign_in create(:leader)

      visit users_communication_path

      expect(page).to have_content "You don't have permission"
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'scheduler shows the page' do
      sign_in create(:scheduler)

      visit users_communication_path

      expect(page).to have_content 'Communication Preferences for Builders'
    end

    it 'data_manager shows the page' do
      sign_in create(:data_manager)

      visit users_communication_path

      expect(page).to have_content 'Communication Preferences for Builders'
    end

    it 'admin shows the page' do
      sign_in create(:admin)

      visit users_communication_path

      expect(page).to have_content 'Communication Preferences for Builders'
    end
  end

  context 'allows for' do
    before do
      event = create(:event)

      # UsersController#communication filters to builders with at least one registration
      5.times do
        user = create :user
        create(:registration, user:, event:)
      end

      sign_in create :admin

      visit users_communication_path
    end

    it 'showing users in a table' do
      expect(page).to have_content 'Communication Preferences for Builders'
      expect(page).to have_css('tbody tr', count: 5)
    end

    it 'searching for a user', js: true do
      user = User.builders.second
      fill_in('Search:', with: user.name)

      expect(page).to have_css('tbody tr', count: 1)
      expect(page).to_not have_content User.first.name
      expect(page).to have_content user.email
    end

    it 'remotely updating user.email_opt_out records', js: true do
      user = User.builders.first

      expect(page).to have_content 'Communication Preferences for Builders'

      find("input#user_#{user.id}").check

      # reload the page
      visit users_communication_path

      # now the checkbox should already be checked
      expect(page).to have_css("input#user_#{user.id}[checked=checked]")
    end
  end
end
