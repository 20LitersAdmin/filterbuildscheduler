# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Inventory show page", type: :system do
  before :each do
    @inventory = FactoryBot.create(:inventory)
  end

  after :all do
    clean_up!
  end

  context "when visited by" do
    it "anon users redirects to sign_in page" do
      visit inventory_path @inventory

      expect(page).to have_content "You need to sign in first"
      expect(page).to have_content "Sign in"
    end

    it "builders redirects to home page" do
      sign_in FactoryBot.create(:user)
      visit inventory_path @inventory

      expect(page).to have_content "You don't have permission"
      expect(page).to have_content "Upcoming Builds"
    end

    it "inventory users shows the page" do
      sign_in FactoryBot.create(:user, does_inventory: true)
      visit inventory_path @inventory

      expect(page).to have_content @inventory.name
      expect(page).to have_content "Full inventory:"
    end

    it "users who receive inventory emails shows the page" do
      sign_in FactoryBot.create(:user, send_inventory_emails: true)
      visit inventory_path @inventory

      expect(page).to have_content @inventory.name
      expect(page).to have_content "Full inventory:"
    end

    it "admins shows the page" do
      sign_in FactoryBot.create(:admin)
      visit inventory_path @inventory

      expect(page).to have_content @inventory.name
      expect(page).to have_content "Full inventory:"
    end
  end
end
