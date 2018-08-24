# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Inventory#index", type: :system do
  before :each do
    @latest = FactoryBot.create(:inventory)
    2.times { FactoryBot.create(:inventory_event, date: Faker::Time.backward(60) )}
    2.times { FactoryBot.create(:inventory_man, date: Faker::Time.backward(60) )}
    FactoryBot.create(:inventory_ship, date: Faker::Time.backward(30))
    FactoryBot.create(:inventory_rec, date: Faker::Time.backward(30))
  end

  after :all do
    clean_up!
  end

  context "when visited by" do
    it "anon users redirects to sign-in page" do
      visit inventories_path

      expect(page).to have_content "You need to sign in first"
      expect(page).to have_content "Sign in"
    end

    it "builders redirects to home page" do
      sign_in FactoryBot.create(:user)

      visit inventories_path

      expect(page).to have_content "You don't have permission"
      expect(page).to have_content "Upcoming Builds"
    end

    it "inventory users shows the page" do
      sign_in FactoryBot.create(:user, does_inventory: true)
      visit inventories_path

      expect(page).to have_content "Current Inventory:"
    end

    it "admins shows the page" do
      sign_in FactoryBot.create(:admin)
      visit inventories_path

      expect(page).to have_content "Current Inventory:"
    end

    it "users who receive inventory emails shows the page" do
      sign_in FactoryBot.create(:user, send_inventory_emails: true)
      visit inventories_path

      expect(page).to have_content "Current Inventory:"
    end
  end

  it "shows all inventories" do
    sign_in FactoryBot.create(:admin)
    visit inventories_path

    expect(page).to have_content @latest.name
    expect(page).to have_css("div.inventory", count: 7)
  end
end
