# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Count labels page", type: :system do
  before :each do
    @latest = FactoryBot.create(:inventory)
  end

  after :all do
    clean_up!
  end

  context "when visited by" do

    it "anon users redirects to sign_in page" do
      visit labels_path()

      expect(page).to have_content "You need to sign in first"
      expect(page).to have_content "Sign in"
    end

    it "builders redirects to home page" do
      sign_in FactoryBot.create(:user)

      visit labels_path()

      expect(page).to have_content "You don't have permission"
      expect(page).to have_content "Upcoming Builds"
    end

    it "leaders redirects to home page" do
      sign_in FactoryBot.create(:leader)

      visit labels_path()

      expect(page).to have_content "You don't have permission"
      expect(page).to have_content "Upcoming Builds"
    end

    it "inventory users shows the page" do
      sign_in FactoryBot.create(:user, does_inventory: true)
      visit labels_path()

      expect(page).to have_content "Choose an item:"
    end

    it "admins shows the page" do
      sign_in FactoryBot.create(:admin)
      visit labels_path()

      expect(page).to have_content "Choose an item:"
    end
  end

  context "shows all counts of" do
    before :each do
      sign_in FactoryBot.create(:admin)
    end

    it "components" do
      3.times { FactoryBot.create(:count_comp, inventory: @latest) }

      visit labels_path

      expect(page).to have_content Component.first.name
      expect(page).to have_content Component.second.name
      expect(page).to have_content Component.third.name
    end

    it "parts" do
      3.times { FactoryBot.create(:count_part, inventory: @latest) }

      visit labels_path

      expect(page).to have_content Part.first.name
      expect(page).to have_content Part.second.name
      expect(page).to have_content Part.third.name
    end

    it "materials" do
      3.times { FactoryBot.create(:count_mat, inventory: @latest) }

      visit labels_path

      expect(page).to have_content Material.first.name
      expect(page).to have_content Material.second.name
      expect(page).to have_content Material.third.name
    end
  end
end
