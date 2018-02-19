require 'rails_helper'

RSpec.describe "Manage registrations:", type: :system, js: true do

  context "anon user" do
    before :each do
      @event = FactoryBot.create(:event)
      @registration = FactoryBot.create(:registration, event: @event)
    end

    it "can't see the registration on the event page" do
      visit event_path @event

      expect(page).to have_content @event.full_title
      expect(page).to_not have_content "You're Registered!"
      expect(page).to_not have_link "Change/Cancel Registration"
    end

    it "can't visit the registration edit page" do
      visit edit_event_registration_path(@event, @registration)

      expect(page).to have_content "You need to sign in first"
      expect(page).to have_content "Sign in"
    end

    it "can't visit the registration index page" do
      visit event_registrations_path @event

      expect(page).to have_content "You need to sign in first"
      expect(page).to have_content "Sign in"
    end
  end

  context "user" do
    before :each do
      @user = FactoryBot.create(:user, signed_waiver_on: Time.now)
      sign_in @user
      @event = FactoryBot.create(:event)
      @registration = FactoryBot.create(:registration, user: @user, event: @event)

      visit event_path @event
    end

    it "sees the registration on the event page" do
      expect(page).to have_content @event.full_title
      expect(page).to have_content "You're Registered!"
      expect(page).to have_link "Change/Cancel Registration"
    end

    it "sees the edit form" do
      click_link "Change/Cancel Registration"

      expect(page).to have_content @event.full_title
      expect(page).to have_content @user.name
      expect(page).to have_field "registration_guests_registered"
      expect(page).to have_field "registration_accommodations"
      expect(page).to have_button "Update"
      expect(page).to have_link "Cancel Registration"
      expect(page).to have_link "Back"
    end

    it "makes edits" do
      click_link "Change/Cancel Registration"

      fill_in "registration_guests_registered", with: "2"
      fill_in "registration_accommodations", with: "accepts edits"

      click_button "Update"

      expect(page).to have_content @event.full_title
      expect(page).to have_content "You're Registered!"
      expect(page).to have_link "Change/Cancel Registration"

      @registration.reload

      expect(@registration.guests_registered).to eq 2
      expect(@registration.accommodations).to eq "accepts edits"
    end

    it "soft-deletes the registration" do
      click_link "Change/Cancel Registration"

      page.accept_confirm { click_link "Cancel Registration" }

      expect(page).to have_content "You are no longer registered."
      expect(page).to have_content @event.full_title
      expect(page).to_not have_content "You're Registered!"
      expect(page).to have_content @user.name
      expect(page).to have_button "Register"
      @registration.reload
      expect(@registration.deleted_at).to_not be_nil
    end

  end

  context "admin" do
    before :each do
      @user = FactoryBot.create(:user, signed_waiver_on: Time.now)
      @admin = FactoryBot.create(:admin)
      sign_in @admin
      @event = FactoryBot.create(:event)
      @registration = FactoryBot.create(:registration, user: @user, event: @event)

      visit event_registrations_path @event
    end

    it "sees an index of registrations for an event" do
      leader_tbl_text = page.all('table#leaders_tbl td').map(&:text)
      builder_tbl_text = page.all('table#builders_tbl td').map(&:text)

      expect(page).to have_content "Registrations for " + @event.full_title
      expect(leader_tbl_text).to eq ["No data available in table"]
      expect(builder_tbl_text).to have_content @user.name
    end

    it "sees the edit form and makes edits" do
      find("a[href='#{edit_event_registration_path(@event, @registration, admin: true)}']").click

      expect(page).to have_content @event.full_title
      expect(page).to have_content @user.name
      expect(page).to have_field "registration_guests_registered"
      expect(page).to have_field "registration_accommodations"
      expect(page).to have_button "Update"
      expect(page).to have_link "Cancel Registration"
      expect(page).to have_link "Back"

      fill_in "registration_guests_registered", with: "3"
      fill_in "registration_accommodations", with: "accepts edits by admin"

      click_button "Update"

      leader_tbl_text = page.all('table#leaders_tbl td').map(&:text)
      builder_tbl_text = page.all('table#builders_tbl td').map(&:text)

      expect(page).to have_content "Registrations for " + @event.full_title
      expect(leader_tbl_text).to eq ["No data available in table"]
      expect(builder_tbl_text).to have_content @user.name

      @registration.reload

      expect(@registration.guests_registered).to eq 3
      expect(@registration.accommodations).to eq "accepts edits by admin"
    end

    it "soft-deletes the registration" do
      find("a[href='#{edit_event_registration_path(@event, @registration, admin: true)}']").click

      page.accept_confirm { click_link "Cancel Registration" }

      leader_tbl_text = page.all('table#leaders_tbl td').map(&:text)
      builder_tbl_text = page.all('table#builders_tbl td').map(&:text)

      expect(page).to have_content "Registrations for " + @event.full_title
      expect(leader_tbl_text).to eq ["No data available in table"]
      expect(leader_tbl_text).to eq ["No data available in table"]

      @registration.reload
      expect(@registration.deleted_at).to_not be_nil
    end
  end
end