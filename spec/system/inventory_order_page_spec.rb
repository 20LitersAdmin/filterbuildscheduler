# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Order supplies page', type: :system do
  context 'when visited by' do
    it 'anon users redirects to sign_in page' do
      visit order_inventories_path

      expect(page).to have_content 'You need to sign in first'
      expect(page).to have_content 'Sign in'
    end

    it 'builders redirects to home page' do
      sign_in create(:user)

      visit order_inventories_path

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'leaders redirects to home page' do
      sign_in create(:leader)

      visit order_inventories_path

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'inventoryists shows the page' do
      sign_in create(:inventoryist)
      visit order_inventories_path

      expect(page).to have_content 'items need to be ordered:'
    end

    it 'users who receive inventory emails shows the page' do
      sign_in create(:user, send_inventory_emails: true)
      visit order_inventories_path

      expect(page).to have_content 'items need to be ordered:'
    end

    it 'admins shows the page' do
      sign_in create(:admin)
      visit order_inventories_path

      expect(page).to have_content 'items need to be ordered:'
    end

    it 'data_managers shows the page' do
      sign_in create(:data_manager)
      visit order_inventories_path

      expect(page).to have_content 'items need to be ordered:'
    end

    it 'schedulers redirects to the home page' do
      sign_in create(:scheduler)

      visit order_inventories_path

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end
  end

  context 'shows items that need to be ordered', js: true do
    before :each do
      create_list :part, 3, below_minimum: true, minimum_on_hand: 30, available_count: 2, supplier: nil
      create_list :material, 3, below_minimum: true, minimum_on_hand: 30, available_count: 2, supplier: nil

      @supplier1 = create :supplier
      create_list :part, 2, below_minimum: true, minimum_on_hand: 30, available_count: 2, supplier: @supplier1
      create_list :material, 2, below_minimum: true, minimum_on_hand: 30, available_count: 2, supplier: @supplier1

      @supplier2 = create :supplier
      create_list :part, 4, below_minimum: true, minimum_on_hand: 30, available_count: 2, supplier: @supplier2
      create_list :material, 4, below_minimum: true, minimum_on_hand: 30, available_count: 2, supplier: @supplier2

      sign_in create(:admin)
      visit order_inventories_path
    end

    it 'in a single table' do
      expect(page).to have_css('table#order_item_tbl')
      expect(page).to have_css('table#order_item_tbl tbody tr', count: (Part.orderable.size + Material.all.size))
    end

    it 'by supplier' do
      click_link 'By Supplier'

      expect(page).to have_css('table.datatable-order-supplier', count: Supplier.all.size + 1)
      expect(page).to have_content @supplier1.name
      expect(page).to have_content @supplier2.name
      expect(page).to have_content 'Items without a supplier:'
    end
  end
end
