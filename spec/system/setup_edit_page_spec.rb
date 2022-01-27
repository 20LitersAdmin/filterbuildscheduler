# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Setup#Edit', type: :system do
  let(:admin) { create :admin }
  let(:event) { create :event }
  let(:setup) { create :setup, event: event, creator: admin }

  context 'when visited by' do
    it 'anon users redirects to sign-in page' do
      visit edit_event_setup_path(event, setup)

      expect(page).to have_content 'You need to sign in first'
      expect(page).to have_content 'Sign in'
    end

    it 'builders redirects to home page' do
      sign_in create(:user)

      visit edit_event_setup_path(event, setup)

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'leaders redirects to home page' do
      sign_in create(:leader)

      visit edit_event_setup_path(event, setup)
      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'inventoryist redirects to home page' do
      sign_in create(:inventoryist)

      visit edit_event_setup_path(event, setup)

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'setup crew redirects to home page' do
      sign_in create(:setup_crew)

      visit edit_event_setup_path(event, setup)
      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'admins shows the page' do
      sign_in admin

      visit edit_event_setup_path(event, setup)
      expect(page).to have_content 'Setup crew members attending:'
    end

    it 'data managers shows the page' do
      sign_in create(:data_manager)

      visit edit_event_setup_path(event, setup)
      expect(page).to have_content 'Setup crew members attending:'
    end

    it 'schedulers shows the page' do
      sign_in create(:scheduler)

      visit edit_event_setup_path(event, setup)
      expect(page).to have_content 'Setup crew members attending:'
    end
  end

  context 'to change a setup event' do
    before do
      sign_in admin

      visit edit_event_setup_path(event, setup)
    end

    it 'by filling out the form' do
      fill_in 'setup_date', with: event.start_time - 2.hours
      click_submit

      expect(page).to have_content 'Setup event updated.'
    end

    context 'by checking boxes next to users' do
      let(:setup_crew) { create_list :setup_crew, 3 }

      it 'registers setup crew members to the setup event' do
        expect(setup.users).to eq []
        visit edit_event_setup_path(event, setup)

        setup_crew.each do |member|
          check "setup_user_ids_#{member.id}"
        end

        click_submit

        expect(page).to have_content 'Setup event updated.'

        expect(setup.reload.users.size).to eq 3
      end
    end
  end
end
