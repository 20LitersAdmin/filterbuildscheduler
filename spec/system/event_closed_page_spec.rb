require 'rails_helper'

RSpec.describe "Events#Closed", type: :system do
  before :each do
    3.times do
      FactoryBot.create(:complete_event)
    end
  end

  after :all do
    clean_up!
  end

  context "when visited by" do
    it "anon users redirects to sign-in page" do
      visit closed_events_path

      expect(page).to have_content "You need to sign in first"
      expect(page).to have_content "Sign in"
    end

    it "builders redirects to home page" do
      sign_in FactoryBot.create(:user)

      visit closed_events_path

      expect(page).to have_content "You don't have permission"
      expect(page).to have_content "Upcoming Builds"
    end

    it "leaders redirects to home page" do
      sign_in FactoryBot.create(:leader)

      visit closed_events_path

      expect(page).to have_content "You don't have permission"
      expect(page).to have_content "Upcoming Builds"
    end

    it "admins shows the page" do
      sign_in FactoryBot.create(:admin)

      visit closed_events_path
      expect(page).to have_content "Closed Builds"
    end
  end

  it "shows events that are closed" do
    event1 = Event.first
    event2 = Event.second
    event3 = Event.third

    event4 = FactoryBot.create(:event, start_time: Time.now + 15.days)

    sign_in FactoryBot.create(:admin)

    visit closed_events_path

    expect(page).to have_content "Closed Builds"

    expect(page).to have_content event1.title
    expect(page).to have_content event2.title
    expect(page).to have_content event3.title
    # Intermittent Failure
    expect(page).not_to have_content event4.title
  end
end