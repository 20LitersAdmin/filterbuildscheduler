require 'rails_helper'

RSpec.describe "User Session", type: :system do

  context "signing in" do
    before :each do
      @user = FactoryBot.create(:user_w_password)
      visit new_user_session_path
    end

    it "shows a form" do
      expect(page).to have_content "Sign in"
      expect(page).to have_field "user_email"
      expect(page).to have_button "Sign in"
      expect(page).to have_link "Don't have an account? Sign up!"
      expect(page).to have_link "Forgot your password?"
    end

    it "signs in a user" do
      fill_in "user_email", with: @user.email
      fill_in "user_password", with: @user.password

      click_button "Sign in"

      expect(page).to have_link "Sign Out"
    end
  end

  context "signing out" do
    let(:user) { create :user }

    it "signs out the current user" do
      sign_in user
      visit root_path

      expect(page).to have_link "Sign Out"

      click_link "Sign Out"

      expect(page).to have_content "Signed out successfully."
    end
  end

  context "signing up" do
    let(:user) { build :user }

    it "shows a form" do
      visit new_user_registration_path

      expect(page).to have_content "Sign up"
      expect(page).to have_field "user_fname"

      fill_in "user_fname", with: user.fname
      fill_in "user_lname", with: user.lname
      fill_in "user_email", with: user.email
      fill_in "user_password", with: "password"
      fill_in "user_password_confirmation", with: "password"

      click_button "Sign up"

      expect(page).to have_content "Welcome! You have signed up successfully."
    end

  end
end