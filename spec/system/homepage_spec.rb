require 'rails_helper'

RSpec.describe "Homepage", type: :system do

  context "an Admin user" do
    it "goes to the homepage" do
      sign_in FactoryBot.create(:admin)
      visit "/"

      expect(page).to have_content "Admin"
    end
  end

  context "a Leader user" do
    it "goes to the homepage" do
      sign_in FactoryBot.create(:leader)
      visit "/"

      expect(page).to have_content "Available functions:"
    end
  end

  context "a Builder user" do
    it "goes to homepage" do
      sign_in FactoryBot.create(:user)
      visit "/"

      expect(page).to have_content "My Account"
    end
  end

  context "no user" do
    it "goes to the homepage" do
      visit "/"

      expect(page).to have_content 'Want a custom build event for your group?'
    end
  end

  context "has some static links" do
    it "has a Give button" do
      visit "/"

      expect(page).to have_link "Give"
    end

    it "has a logo that links to 20liters.org" do
      visit "/"

      expect(page).to have_link("", href: "https://20liters.org")
    end
  end
 
end