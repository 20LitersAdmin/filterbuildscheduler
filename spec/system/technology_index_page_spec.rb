# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Technology index page", type: :system do
  before :each do
    3.times { FactoryBot.create(:technology) }
  end

  after :all do
    clean_up!
  end

  context "when visited by" do
    it "anon users redirects to sign-in page" do
      visit technologies_path

      expect(page).to have_content "You need to sign in first"
      expect(page).to have_content "Sign in"
    end

    it "builders redirects to home page" do
      sign_in FactoryBot.create(:user)

      visit technologies_path

      expect(page).to have_content "You don't have permission"
      expect(page).to have_content "Upcoming Builds"
    end

    it "inventory users shows the page" do
      sign_in FactoryBot.create(:user, does_inventory: true)
      visit technologies_path

      expect(page).to have_content "Choose a Technology for a list of all items:"
    end

    it "admins shows the page" do
      sign_in FactoryBot.create(:admin)
      visit technologies_path

      expect(page).to have_content "Choose a Technology for a list of all items:"
    end

    it "users who receive inventory emails shows the page" do
      sign_in FactoryBot.create(:user, send_inventory_emails: true)
      visit technologies_path

      expect(page).to have_content "Choose a Technology for a list of all items:"
    end
  end

  it "shows all technologies" do
    sign_in FactoryBot.create(:admin)
    visit technologies_path

    expect(page).to have_content Technology.first.name
    expect(page).to have_content Technology.second.name
    expect(page).to have_content Technology.third.name
  end
end
