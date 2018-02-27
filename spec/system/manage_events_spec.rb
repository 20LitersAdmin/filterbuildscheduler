require 'rails_helper'

RSpec.describe "Managing events:", type: :system, js: true do
  before :each do
    @event = FactoryBot.create(:event)

    2.times do
      FactoryBot.create(:registration, event: @event)
    end
  end

  after :all do
    clean_up!
  end

  context "anon user" do
    it "can't visit the edit event page" do
      visit edit_event_path @event

      expect(page).to have_content "You need to sign in first"
      expect(page).to have_content "Sign in"
    end
  end

  context "builder" do
    it "can't visit the edit event page" do
      builder = FactoryBot.create(:user)
      sign_in builder
      visit edit_event_path @event

      expect(page).to have_content "You don't have permission"
      expect(page).to have_content "Upcoming Builds"
    end
  end

  context "leader" do
    before :each do
      @user = FactoryBot.create(:leader, send_notification_emails: true)
      sign_in @user
      visit edit_event_path @event
    end

    it "can visit the edit event page" do
      expect(page).to have_field "event_title"
      expect(page).to have_field "event_location_id"
      expect(page).to have_field "event_is_private"
      expect(page).to have_button "Update Event"
      expect(page).to have_link "Back"

    end

    it "can change values of the event, which sends an email" do
      fill_in "event_title", with: "Leader can name the event"
      fill_in "event_start_time", with: "Sep 11 2021 06:30 PM"
      fill_in "event_end_time", with: "Sep 11 2021 09:00 PM"
      fill_in "event_description", with: "Leader can provide a description"
      check "event_is_private"
      fill_in "event_contact_name", with: @user.name
      fill_in "event_contact_email", with: @user.email

      first_count = ActionMailer::Base.deliveries.count

      click_button "Update Event"

      expect(page).to have_content "Event updated."
      @event.reload
      expect(page).to have_content @event.full_title
      expect(@event.title).to eq "Leader can name the event"
      expect(@event.description).to eq "Leader can provide a description"
      expect(@event.format_time_range).to eq "Sat, 9/11  6:30pm -  9:00pm"

      second_count = ActionMailer::Base.deliveries.count
      expect(second_count).to eq first_count + 3 # 2 registrants and the leader
    end

    it "can soft-delete an event" do
      expect(page).to have_link "Cancel Event"

      first_count = Delayed::Job.count

      page.accept_confirm { click_link "Cancel Event" }

      expect(page).to have_content "Event cancelled."
      expect(page).to have_link "Manage Cancelled Events"
      @event.reload
      expect(@event.deleted_at).to_not be_nil

      second_count = Delayed::Job.count
      expect(second_count).to eq first_count + 3 # 2 registrants and the leader
    end
  end

  context "admin" do
    before :each do
      @user = FactoryBot.create(:admin, send_notification_emails: true)
      sign_in @user
      visit edit_event_path @event
    end

    it "can visit the edit event page" do
      expect(page).to have_field "event_title"
      expect(page).to have_field "event_location_id"
      expect(page).to have_field "event_is_private"
      expect(page).to have_button "Update Event"
      expect(page).to have_link "Back"
    end

    it "can change values of the event, which sends an email" do
      fill_in "event_title", with: "Admin can name the event"
      fill_in "event_start_time", with: "Sep 11 2021 06:30 PM"
      fill_in "event_end_time", with: "Sep 11 2021 09:00 PM"
      fill_in "event_description", with: "Admin can provide a description"
      check "event_is_private"
      fill_in "event_contact_name", with: @user.name
      fill_in "event_contact_email", with: @user.email

      first_count = ActionMailer::Base.deliveries.count

      click_button "Update Event"

      expect(page).to have_content "Event updated."
      @event.reload
      expect(page).to have_content @event.full_title
      expect(@event.title).to eq "Admin can name the event"
      expect(@event.description).to eq "Admin can provide a description"
      expect(@event.format_time_range).to eq "Sat, 9/11  6:30pm -  9:00pm"

      second_count = ActionMailer::Base.deliveries.count
      expect(second_count).to eq first_count + 3 # 2 registrants and the admin
    end

    it "can soft-delete an event, which sends an email" do
      expect(page).to have_link "Cancel Event"

      first_count = Delayed::Job.count

      page.accept_confirm { click_link "Cancel Event" }

      expect(page).to have_content "Event cancelled."
      expect(page).to have_link "Manage Cancelled Events"
      @event.reload
      expect(@event.deleted_at).to_not be_nil

      second_count = Delayed::Job.count
      expect(second_count).to eq first_count + 3 # 2 registrants and the admin
    end
  end
end