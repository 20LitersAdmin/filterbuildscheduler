# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Count label page', type: :system do
  before :each do
    @latest = FactoryBot.create(:inventory)
    @count = FactoryBot.create(:count_part, inventory: @latest)
  end

  after :all do
    clean_up!
  end

  context 'when visited by' do

    it 'anon users redirects to sign_in page' do
      visit label_inventory_count_path(@latest, @count)

      expect(page).to have_content 'You need to sign in first'
      expect(page).to have_content 'Sign in'
    end

    it 'builders redirects to home page' do
      sign_in FactoryBot.create(:user)

      visit label_inventory_count_path(@latest, @count)

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'leaders redirects to home page' do
      sign_in FactoryBot.create(:leader)

      visit label_inventory_count_path(@latest, @count)

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'inventory users shows the page' do
      sign_in FactoryBot.create(:user, does_inventory: true)
      visit label_inventory_count_path(@latest, @count)

      expect(page).to have_content 'Printing instructions:'
    end

    it 'admins shows the page' do
      sign_in FactoryBot.create(:admin)
      visit label_inventory_count_path(@latest, @count)

      expect(page).to have_content 'Printing instructions:'
    end
  end
end
