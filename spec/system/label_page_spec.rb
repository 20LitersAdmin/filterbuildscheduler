# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Label page', type: :system do
  let(:item) { create :part }

  context 'when visited by' do
    it 'anon users redirects to sign_in page' do
      visit label_path(item.uid)

      expect(page).to have_content 'You need to sign in first'
      expect(page).to have_content 'Sign in'
    end

    it 'builders redirects to home page' do
      sign_in create(:user)

      visit label_path(item.uid)

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'leaders shows the page' do
      sign_in create(:leader)

      visit label_path(item.uid)

      expect(page).to have_content 'Printing instructions:'
    end

    it 'inventory users shows the page' do
      sign_in create(:inventoryist)
      visit label_path(item.uid)

      expect(page).to have_content 'Printing instructions:'
    end

    it 'admins shows the page' do
      sign_in create(:admin)
      visit label_path(item.uid)

      expect(page).to have_content 'Printing instructions:'
    end

    it 'schedulers shows the page' do
      sign_in create(:scheduler)
      visit label_path(item.uid)

      expect(page).to have_content 'Printing instructions:'
    end

    it 'data_managers shows the page' do
      sign_in create(:data_manager)
      visit label_path(item.uid)

      expect(page).to have_content 'Printing instructions:'
    end
  end

  context 'shows' do
    before do
      sign_in create(:admin)
      visit label_path(item.uid)
    end

    it 'a page with 10 labels' do
      expect(page).to have_content item.name, count: 10
      expect(page).to have_content item.uid, count: 10
    end

    it 'the print navbar' do
      expect(page).to have_link 'Print'
    end
  end
end
