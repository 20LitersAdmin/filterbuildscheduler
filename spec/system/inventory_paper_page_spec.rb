# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Inventory#paper' do
  context 'when visited by a' do
    it 'anon user, it redirects to sign-in page' do
      visit paper_inventories_path

      expect(page).to have_content 'You need to sign in first'
      expect(page).to have_content 'Sign in'
    end

    it 'builder, it redirects to home page' do
      sign_in create :user
      visit paper_inventories_path

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'leader, it redirects to home page' do
      sign_in create :leader
      visit paper_inventories_path

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'inventoryist, it shows the page' do
      sign_in create :inventoryist
      visit paper_inventories_path

      expect(page).to have_content 'Printable inventory'
    end

    it 'scheduler, it redirects to home page' do
      sign_in create :scheduler
      visit paper_inventories_path

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'data_manager, it shows the page' do
      sign_in create :data_manager
      visit paper_inventories_path

      expect(page).to have_content 'Printable inventory'
    end

    it 'admin, it shows the page' do
      sign_in create :admin
      visit paper_inventories_path

      expect(page).to have_content 'Printable inventory'
    end
  end
end
