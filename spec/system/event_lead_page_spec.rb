require 'rails_helper'

RSpec.describe "Events#Lead", type: :system do
  before :each do
    3.times { FactoryBot.create(:event) }
  end

  after :all do
    clean_up!
  end

  context "when visited by" do
    it "anon users redirects to sign-in page" do
      visit lead_events_path

      expect(page).to have_content "You need to sign in first"
      expect(page).to have_content "Sign in"
    end

    it "builders redirects to home page" do
      sign_in FactoryBot.create(:user)

      visit lead_events_path

      expect(page).to have_content "You don't have permission"
      expect(page).to have_content "Upcoming Builds"
    end

    it "leaders shows the page" do
      sign_in FactoryBot.create(:leader)

      visit lead_events_path
      expect(page).to have_content "Builds that need leaders"
    end

    it "admins shows the page" do
      sign_in FactoryBot.create(:admin)

      visit lead_events_path
      expect(page).to have_content "Builds that need leaders"
    end
  end

  it "shows events still needing leaders" do
    event1 = Event.first
    event2 = Event.second
    event3 = Event.third

    event4 = FactoryBot.create(:event, min_leaders: 1, max_leaders: 1)
    FactoryBot.create(:registration_leader, event: event4)

    sign_in FactoryBot.create(:leader)

    visit lead_events_path

    expect(page).to have_content event1.title
    expect(page).to have_content event2.title
    expect(page).to have_content event3.title
    expect(page).not_to have_content event4.title
  end
end