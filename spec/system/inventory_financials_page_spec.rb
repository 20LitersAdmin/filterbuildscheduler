# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Inventory financials page", type: :system do
  before :each do
    @inventory = FactoryBot.create(:inventory, completed_at: Time.now)
  end

  after :all do
    clean_up!
  end

  context "when visited by" do
    it "anon users redirects to sign_in page" do
      visit financials_inventories_path

      expect(page).to have_content "You need to sign in first"
      expect(page).to have_content "Sign in"
    end

    it "builders redirects to home page" do
      sign_in FactoryBot.create(:user)
      visit financials_inventories_path

      expect(page).to have_content "You don't have permission"
      expect(page).to have_content "Upcoming Builds"
    end

    it "inventory users shows the page" do
      sign_in FactoryBot.create(:user, does_inventory: true)
      visit financials_inventories_path

      expect(page).to have_content "Financial status of inventory"
    end

    it "users who receive inventory emails shows the page" do
      sign_in FactoryBot.create(:user, send_inventory_emails: true)
      visit financials_inventories_path

      expect(page).to have_content "Financial status of inventory"
    end

    it "admins shows the page" do
      sign_in FactoryBot.create(:admin)
      visit financials_inventories_path

      expect(page).to have_content "Financial status of inventory"
    end
  end
end
