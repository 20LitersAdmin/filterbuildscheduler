# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Combinations#show' do
  let(:technology) { create :technology }

  context 'when visited by a' do
    it 'anon user, it redirects to sign-in page' do
      visit combination_path technology.uid

      expect(page).to have_content 'You need to sign in first'
      expect(page).to have_content 'Sign in'
    end

    it 'builder, it redirects to home page' do
      sign_in create :user
      visit combination_path technology.uid

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'leader, it redirects to home page' do
      sign_in create :leader
      visit combination_path technology.uid

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'inventoryist, it shows the page' do
      sign_in create :inventoryist
      visit combination_path technology.uid

      expect(page).to have_content "#{technology.uid}: #{technology.name} (#{technology.available_count} available; #{technology.can_be_produced} produceable)"
    end

    it 'scheduler, it redirects to home page' do
      sign_in create :scheduler
      visit combination_path technology.uid

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'data_manager, it shows the page' do
      sign_in create :data_manager
      visit combination_path technology.uid

      expect(page).to have_content "#{technology.uid}: #{technology.name} (#{technology.available_count} available; #{technology.can_be_produced} produceable)"
    end

    it 'admin, it shows the page' do
      sign_in create :admin
      visit combination_path technology.uid

      expect(page).to have_content "#{technology.uid}: #{technology.name} (#{technology.available_count} available; #{technology.can_be_produced} produceable)"
    end
  end

  context 'with assemblies' do
    before do
      @tech = create :technology
      4.times do
        asbly = create :assembly_tech, combination: @tech
        create_list :assembly_comps, 2, combination: asbly.item
      end

      sign_in create :admin

      visit combination_path @tech.uid

      expect(page).to have_content "#{@tech.uid}: #{@tech.name} (#{@tech.available_count} available; #{@tech.can_be_produced} produceable)"
    end

    it 'lists first-level sub-assemblies and data' do
      expect(page).to have_link 'Tech List'
      expect(page).to have_link 'Edit'
      expect(page).to have_css('table.show_combination_tbl tbody tr', count: 4)
    end

    it 'can show all level sub-assemblies' do
      click_link 'Show sub-assemblies'

      expect(page).to have_link 'Hide sub-assemblies'
      expect(page).to have_css('table.show_combination_tbl tbody tr', count: 12)
    end
  end
end
