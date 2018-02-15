require 'rails_helper'

RSpec.describe "User#edit", type: :system do

  context "when a user has a password" do

    before :each do
      @user_w_password = FactoryBot.create(:user_w_password)
      sign_in @user_w_password
      visit edit_user_path @user_w_password
    end

    it "displays a form" do
      expect(page).to have_content "Edit Your Profile"
      expect(page).to have_field "user_fname"
    end

    it "accepts changes" do
      fill_in "user_fname", with: "Ross"
      fill_in "user_lname", with: "Hunter"

      click_button "Update"

      @user_w_password.reload
      expect(@user_w_password.name).to eq "Ross Hunter"
    end

  end

  context "when a user doesn't have a password" do
    let(:user) { create :user }

    it "encourages them to set a password" do
      sign_in user
      visit edit_user_path user

      expect(page).to have_content "You haven't set a password yet, please do so now."
      expect(page).to have_css("label.has-error")
      expect(page).to have_css("input#user_password.has-error")
    end

  end
end