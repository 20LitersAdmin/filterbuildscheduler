# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User#edit', type: :system do
  after :all do
    clean_up!
  end

  context 'when a user has a password' do
    before :each do
      @user = FactoryBot.create(:user_w_password)
      sign_in @user
      visit edit_user_path @user
    end

    it 'displays a form' do
      expect(page).to have_content 'Edit Your Profile'
      expect(page).to have_field 'user_fname'
    end

    it 'accepts changes' do
      fill_in 'user_fname', with: 'Ross'
      fill_in 'user_lname', with: 'Hunter'

      click_button 'Update'

      expect(page).to have_content 'Info updated!'

      @user.reload
      expect(page).to have_content @user.name
      expect(@user.name).to eq 'Ross Hunter'
    end
  end

  context 'when a user doesn\'t have a password' do
    let(:user) { create :user }

    it 'encourages them to set a password' do
      sign_in user
      visit edit_user_path user

      expect(page).to have_content 'You haven\'t set a password yet, please do so now.'
      expect(page).to have_css('label.has-error')
      expect(page).to have_css('input#user_password.has-error')
    end
  end

  context 'when changing the password' do
    before :each do
      @user = FactoryBot.create(:user_w_password)
      sign_in @user
      visit edit_user_path @user
    end

    it 'changes the password, sends an email, and logs out the user' do
      fill_in 'user_password', with: 'mybirthday'
      fill_in 'user_password_confirmation', with: 'mybirthday'

      first_count = ActionMailer::Base.deliveries.count

      click_button 'Update'

      expect(page).to have_content 'You need to sign in first'

      second_count = ActionMailer::Base.deliveries.count
      expect(second_count).to eq first_count + 1

      email = ActionMailer::Base.deliveries.last

      expect(email.subject).to eq '[20 Liters] Your password was changed'
      expect(email.to[0]).to eq @user.email
      expect(email.body.parts.first.body.raw_source).to have_content 'Your password has just been changed in the Filter Build system.'

      @user.reload
      expect(@user.valid_password?('mybirthday')).to be true
    end
  end
end
