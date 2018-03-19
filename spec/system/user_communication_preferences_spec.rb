require 'rails_helper'

RSpec.describe "Users#communication page", type: :system, js: true do
  before :each do
    event = FactoryBot.create(:event)
    5.times { FactoryBot.create(:user) }

    User.all.each do |u|
      FactoryBot.create(:registration, user: u, event: event)
    end
  end

  after :all do
    clean_up!
  end

  context "when visited by" do
    it "anon users redirects to sign-in page" do
      visit users_communication_path

      expect(page).to have_content "You need to sign in first"
      expect(page).to have_content "Sign in"
    end

    it "builders redirects to home page" do
      sign_in FactoryBot.create(:user)

      visit users_communication_path

      expect(page).to have_content "You don't have permission"
      expect(page).to have_content "Upcoming Builds"
    end

    it "leaders redirects to home page" do
      sign_in FactoryBot.create(:leader)

      visit users_communication_path

      expect(page).to have_content "You don't have permission"
      expect(page).to have_content "Upcoming Builds"
    end
  end

  context "when visited by an admin" do
    before :each do
      sign_in FactoryBot.create(:admin)
      visit users_communication_path
    end

    it "shows users in a table" do
      expect(page).to have_content "Communication Preferences"
      expect(page).to have_button "Update Email Opt Outs"
      expect(page).to have_css("tbody tr", count: 5)
    end

    it "searches for a user" do
      user = User.second
      fill_in("Search:", with: user.name)

      expect(page).to have_css("tbody tr", count: 1)
      expect(page).to_not have_content User.first.name
      expect(page).to have_content user.email
    end

    it "allows for batch processing of email_opt_outs" do
      user1 = User.first
      user2 = User.second
      user3 = User.third
      expect(user1.email_opt_out).to eq false
      expect(user2.email_opt_out).to eq false
      expect(user3.email_opt_out).to eq false

      find(:css, "input[value='#{user1.id.to_s}']").set(true)
      find(:css, "input[value='#{user3.id.to_s}']").set(true)
      click_button "Update Email Opt Outs"

      user1.reload
      user2.reload
      user3.reload
      expect(user1.email_opt_out).to eq true
      expect(user2.email_opt_out).to eq false
      expect(user3.email_opt_out).to eq true
    end
  end
end