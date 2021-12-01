# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Inventory#index', type: :system do
  let(:inventory) { create :inventory }

  context 'when visited by' do
    it 'anon users redirects to sign-in page' do
      inventory
      visit inventories_path

      expect(page).to have_content 'You need to sign in first'
      expect(page).to have_content 'Sign in'
    end

    it 'builders redirects to home page' do
      inventory
      sign_in create(:user)

      visit inventories_path

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'inventoryists shows the page' do
      inventory
      sign_in create(:inventoryist)
      visit inventories_path

      expect(page).to have_content 'Inventory Counts:'
    end

    it 'admins shows the page' do
      inventory
      sign_in create(:admin)
      visit inventories_path

      expect(page).to have_content 'Inventory Counts:'
    end

    it 'users who receive inventory emails shows the page' do
      inventory
      sign_in create(:user, send_inventory_emails: true)
      visit inventories_path

      expect(page).to have_content 'Inventory Counts:'
    end

    it 'data managers shows the page' do
      inventory
      sign_in create(:data_manager)
      visit inventories_path

      expect(page).to have_content 'Inventory Counts:'
    end

    it 'leaders redirects to home page' do
      inventory
      sign_in create(:leader)
      visit inventories_path

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'schedulers redirects to home page' do
      inventory
      sign_in create(:scheduler)
      visit inventories_path

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end
  end

  context 'with a current inventory with counts' do
    let(:counts) { create_list :count, 2, inventory: inventory }

    it 'shows current inventory' do
      inventory
      counts

      sign_in create :admin
      visit inventories_path

      expect(page).to have_content 'Inventory Counts:'
      expect(page).to have_content 'Current Inventory:'
    end
  end

  it 'shows a table of items and their latest counts' do
    inventory
    create_list :technology, 2, list_worthy: true
    create_list :component, 3
    create_list :part, 5
    create_list :material, 3

    sign_in create :admin
    visit inventories_path

    expect(page).to have_content 'Inventory Counts:'

    within('table#item_tbl tbody') do
      expect(all('tr').count).to eq 13
    end
  end
end
