# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Account page', type: :system do
  context 'when not signed in' do
    let(:user) { create :user }

    it 'requires sign_in' do
      visit show_user_path user
      expect(page).to have_content 'You need to sign in first.'
      expect(page).to have_button 'Sign in'
    end
  end

  context 'as a builder' do
    let(:user) { create :user }
    let(:other_user) { create :user }

    it 'can be visited' do
      sign_in user
      visit show_user_path user
      expect(page).to have_content user.name
    end

    it 'doesn\'t have a qualifications section' do
      sign_in user
      visit show_user_path user
      expect(page).not_to have_content 'Qualifications'
    end

    it 'does\'t allow viewing other users' do
      sign_in user
      visit show_user_path other_user

      expect(page).to have_content 'You don\'t have permission.'
      expect(page).to have_content 'Upcoming Builds'
    end
  end

  context 'as a leader' do
    let(:leader) { create :leader }

    it 'has a qualifications section' do
      sign_in leader
      visit show_user_path leader
      expect(page).to have_content 'Qualifications'
    end
  end

  context 'as an admin' do
    let(:admin) { create :admin }
    let(:user) { create :user }

    it 'allows admins to view other users' do
      sign_in admin
      visit show_user_path user
      expect(page).to have_content user.name
    end

    it 'allows admins to view their own' do
      sign_in admin
      visit show_user_path admin
      expect(page).to have_content admin.name
      expect(page).to have_content 'Qualifications'
    end
  end

  context 'based on the presence of a password' do
    let(:user) { create :user }
    let(:user_w_password) { create :user_w_password }

    it 'when not present, encourages them to set one' do
      sign_in user
      visit show_user_path user

      expect(page).to have_content 'You haven\'t set your password yet, please do so now.'
      expect(page).to have_link('Set your password!')
    end

    it 'when present, doesn\'t need to encourage' do
      sign_in user_w_password
      visit show_user_path user_w_password

      expect(page).not_to have_content 'You haven\'t set your password yet, please do so now.'
      expect(page).to have_link('Edit Your Information')
    end
  end
end
