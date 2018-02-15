require 'rails_helper'

RSpec.describe "Account page", type: :system do

  context "as a builder" do
    let(:user) { create :user }

    it "can be visited" do
      sign_in user
      visit show_user_path user
      expect(page).to have_content user.name
    end

    it "doesn't have a qualifications section" do
      sign_in user
      visit show_user_path user
      expect(page).not_to have_content "Qualifications"
    end

  end
  

  context "as a leader" do
    let(:leader) { create :leader }

    it "has a qualifications section" do
      sign_in leader
      visit show_user_path leader
      expect(page).to have_content "Qualifications"
    end
    
  end

  context "as an admin" do
    let(:admin) { create :admin }
    let(:user) { create :user }

    it "allows admins to view other users" do
      sign_in admin
      visit show_user_path user
      expect(page).to have_content user.name
    end

    it "allows admins to view their own" do
      sign_in admin
      visit show_user_path admin
      expect(page).to have_content admin.name
      expect(page).to have_content "Qualifications"
    end

  end

end