# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Labels page', type: :system do
  context 'when visited by' do
    it 'anon users redirects to sign_in page' do
      visit labels_path

      expect(page).to have_content 'You need to sign in first'
      expect(page).to have_content 'Sign in'
    end

    it 'builders redirects to home page' do
      sign_in create(:user)
      visit labels_path

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'leaders shows the page' do
      sign_in create(:leader)
      visit labels_path

      expect(page).to have_content 'Select labels to print'
    end

    it 'inventory users shows the page' do
      sign_in create(:user, does_inventory: true)
      visit labels_path

      expect(page).to have_content 'Select labels to print'
    end

    it 'admins shows the page' do
      sign_in create(:admin)
      visit labels_path

      expect(page).to have_content 'Select labels to print'
    end
  end

  context 'shows all' do
    before :each do
      sign_in create(:admin)

      3.times do
        create(:part)
        create(:material)
        create(:component)
        create(:technology)
      end
    end

    it 'technologies' do
      visit labels_path

      expect(page).to have_content Technology.first.name
      expect(page).to have_content Technology.second.name
      expect(page).to have_content Technology.third.name
    end

    it 'components' do
      visit labels_path

      expect(page).to have_content Component.first.name
      expect(page).to have_content Component.second.name
      expect(page).to have_content Component.third.name
    end

    it 'parts' do
      visit labels_path

      expect(page).to have_content Part.first.name
      expect(page).to have_content Part.second.name
      expect(page).to have_content Part.third.name
    end

    it 'materials' do
      visit labels_path

      expect(page).to have_content Material.first.name
      expect(page).to have_content Material.second.name
      expect(page).to have_content Material.third.name
    end
  end
end
