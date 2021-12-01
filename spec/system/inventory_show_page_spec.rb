# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Inventory show page', type: :system do
  let(:inventory) { create :inventory }

  context 'when visited by' do
    it 'anon users redirects to sign_in page' do
      visit inventory_path inventory

      expect(page).to have_content 'You need to sign in first'
      expect(page).to have_content 'Sign in'
    end

    it 'builders redirects to home page' do
      sign_in create(:user)

      visit inventory_path inventory

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'leaders redirects to home page' do
      sign_in create(:leader)

      visit inventory_path inventory

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'inventoryists shows the page' do
      sign_in create(:inventoryist)
      visit inventory_path inventory

      expect(page).to have_content "#{inventory.name} Inventory"
    end

    it 'users who receive inventory emails shows the page' do
      sign_in create(:user, send_inventory_emails: true)
      visit inventory_path inventory

      expect(page).to have_content "#{inventory.name} Inventory"
    end

    it 'admins shows the page' do
      sign_in create(:admin)
      visit inventory_path inventory

      expect(page).to have_content "#{inventory.name} Inventory"
    end

    it 'data_managers shows the page' do
      sign_in create(:data_manager)
      visit inventory_path inventory

      expect(page).to have_content "#{inventory.name} Inventory"
    end

    it 'schedulers redirects to the home page' do
      sign_in create(:scheduler)

      visit inventory_path inventory

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end
  end
end
