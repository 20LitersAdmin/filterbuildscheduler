# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Combinations#index' do
  let(:techs) { create_list :technology, 3 }

  context 'when visited by a' do
    it 'anon user, it redirects to sign-in page' do
      visit combinations_path

      expect(page).to have_content 'You need to sign in first'
      expect(page).to have_content 'Sign in'
    end

    it 'builder, it redirects to home page' do
      sign_in create :user
      visit combinations_path

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'leader, it redirects to home page' do
      sign_in create :leader
      visit combinations_path

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'inventoryist, it shows the page' do
      sign_in create :inventoryist
      visit combinations_path

      expect(page).to have_content 'Technologies:'
    end

    it 'scheduler, it redirects to home page' do
      sign_in create :scheduler
      visit combinations_path

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'data_manager, it shows the page' do
      sign_in create :data_manager
      visit combinations_path

      expect(page).to have_content 'Technologies:'
    end

    it 'admin, it shows the page' do
      sign_in create :admin
      visit combinations_path

      expect(page).to have_content 'Technologies:'
    end
  end

  it 'shows a list of technologies' do
    techs
    sign_in create :admin
    visit combinations_path

    expect(page).to have_content 'Technologies:'
    expect(page).to have_css('table#list_item_tbl tbody tr', count: 3)
  end
end
