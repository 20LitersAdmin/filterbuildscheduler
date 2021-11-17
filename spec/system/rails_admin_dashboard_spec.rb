# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Rails admin dashboard', type: :system do
  after :all do
    clean_up!
  end

  context 'when visited by' do
    it 'anon users redirects to sign_in page' do
      visit '/admin'

      expect(page).to have_content 'You need to sign in or sign up before continuing.'
      expect(page).to have_content 'Sign in'
    end

    it 'builders redirects to home page' do
      sign_in FactoryBot.create(:user)

      visit '/admin'

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end
  end

  context 'when visited by' do
    context 'admin' do
      before :each do
        sign_in FactoryBot.create(:admin)
        visit '/admin'
      end

      it 'shows the dashboard' do
        expect(page).to have_content 'Site Administration'
      end

      it 'shows specific blocks' do
        expect(page).to have_content 'Scheduler Links'
        expect(page).to have_content 'Build Leader Links'
        expect(page).to have_content 'Data Manager Links'
        expect(page).to have_content 'Inventory Links'
        expect(page).to have_content 'Event Management'
        expect(page).to have_content 'Technology Management'
        expect(page).to have_content 'User Management'
        expect(page).not_to have_content 'Email Sync System'
      end
    end

    context 'leader' do
      before :each do
        sign_in FactoryBot.create(:leader)
        visit '/admin'
      end

      it 'shows the dashboard' do
        expect(page).to have_content 'Site Administration'
      end

      it 'shows specific blocks' do
        expect(page).not_to have_content 'Scheduler Links'
        expect(page).to have_content 'Build Leader Links'
        expect(page).not_to have_content 'Data Manager Links'
        expect(page).not_to have_content 'Inventory Links'
        expect(page).to have_content 'Event Management'
        expect(page).not_to have_content 'Technology Management'
        expect(page).not_to have_content 'User Management'
        expect(page).not_to have_content 'Email Sync System'
      end
    end

    context 'scheduler' do
      before :each do
        sign_in FactoryBot.create(:scheduler)
        visit '/admin'
      end

      it 'shows the dashboard' do
        expect(page).to have_content 'Site Administration'
      end

      it 'shows specific blocks' do
        expect(page).to have_content 'Scheduler Links'
        expect(page).not_to have_content 'Build Leader Links'
        expect(page).not_to have_content 'Data Manager Links'
        expect(page).not_to have_content 'Inventory Links'
        expect(page).to have_content 'Event Management'
        expect(page).not_to have_content 'Technology Management'
        expect(page).not_to have_content 'User Management'
        expect(page).not_to have_content 'Email Sync System'
      end
    end

    context 'data_manager' do
      before :each do
        sign_in FactoryBot.create(:data_manager)
        visit '/admin'
      end

      it 'shows the dashboard' do
        expect(page).to have_content 'Site Administration'
      end

      it 'shows specific blocks' do
        expect(page).not_to have_content 'Scheduler Links'
        expect(page).not_to have_content 'Build Leader Links'
        expect(page).to have_content 'Data Manager Links'
        expect(page).not_to have_content 'Inventory Links'
        expect(page).to have_content 'Event Management'
        expect(page).not_to have_content 'Technology Management'
        expect(page).not_to have_content 'User Management'
        expect(page).not_to have_content 'Email Sync System'
      end
    end

    context 'inventoryist' do
      before :each do
        sign_in FactoryBot.create(:inventoryist)
        visit '/admin'
      end

      it 'shows the dashboard' do
        expect(page).to have_content 'Site Administration'
      end

      it 'shows specific blocks' do
        expect(page).not_to have_content 'Scheduler Links'
        expect(page).not_to have_content 'Build Leader Links'
        expect(page).not_to have_content 'Data Manager Links'
        expect(page).to have_content 'Inventory Links'
        expect(page).not_to have_content 'Event Management'
        expect(page).not_to have_content 'Technology Management'
        expect(page).not_to have_content 'User Management'
        expect(page).not_to have_content 'Email Sync System'
      end
    end

    context 'oauth_admin' do
      before :each do
        sign_in FactoryBot.create(:oauth_admin)
        visit '/admin'
      end

      it 'shows the dashboard' do
        expect(page).to have_content 'Site Administration'
      end

      it 'shows specific blocks' do
        expect(page).not_to have_content 'Scheduler Links'
        expect(page).not_to have_content 'Build Leader Links'
        expect(page).not_to have_content 'Data Manager Links'
        expect(page).not_to have_content 'Inventory Links'
        expect(page).not_to have_content 'Event Management'
        expect(page).not_to have_content 'Technology Management'
        expect(page).not_to have_content 'User Management'
        expect(page).to have_content 'Email Sync System'
      end
    end
  end
end
