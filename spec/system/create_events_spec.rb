# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Create events:", type: :system do
  after :all do
    clean_up!
  end

  context "anon user" do
    it "can't visit the new event page" do
      visit new_event_path

      expect(page).to have_content "You need to sign in first"
      expect(page).to have_content "Sign in"
    end
  end

  context "builder" do
    it "can't visit the new event page" do
      builder = FactoryBot.create(:user)
      sign_in builder
      visit new_event_path

      expect(page).to have_content "You don't have permission"
      expect(page).to have_content "Upcoming Builds"
    end
  end

  context "leader" do
    before :each do
      @user = FactoryBot.create(:leader, send_notification_emails: true)
      @location = FactoryBot.create(:location)
      @technology = FactoryBot.create(:technology)
      sign_in @user
      visit new_event_path
    end

    it "can visit the new event page" do
      expect(page).to have_field "event_title"
      expect(page).to have_field "event_location_id"
      expect(page).to have_field "event_is_private"
      expect(page).to have_button "Submit"
      expect(page).to have_link "Back"
    end

    it "can fill in and submit the event from, which triggers an email" do
      event = FactoryBot.build(:event, location: @location, technology: @technology)

      fill_in "event_title", with: event.title
      find('#event_location_id').find(:css, 'option[value="' + @location.id.to_s+ '"]').select_option
      fill_in "event_start_time", with: event.start_time
      fill_in "event_end_time", with: event.end_time
      fill_in "event_description", with: "Capybara did this"
      find('#event_technology_id').find(:css, 'option[value="' + @technology.id.to_s + '"]').select_option
      fill_in "event_min_leaders", with: event.min_leaders
      fill_in "event_max_leaders", with: event.max_leaders
      fill_in "event_min_registrations", with: event.min_registrations
      fill_in "event_max_registrations", with: event.max_registrations

      first_count = Delayed::Job.count

      click_button "Submit"

      expect(page).to have_content "Upcoming Builds"
      saved_event = Event.last
      expect(saved_event.title).to eq event.title
      expect(saved_event.location).to eq event.location
      expect(saved_event.technology).to eq event.technology

      second_count = Delayed::Job.count
      expect(second_count).to eq first_count + 1
    end
  end

  context "Admin" do
    before :each do
      @user = FactoryBot.create(:admin, send_notification_emails: true)
      @location = FactoryBot.create(:location)
      @technology = FactoryBot.create(:technology)
      sign_in @user
      visit new_event_path
    end

    it "can visit the new event page" do
      expect(page).to have_field "event_title"
      expect(page).to have_field "event_location_id"
      expect(page).to have_field "event_is_private"
      expect(page).to have_button "Submit"
      expect(page).to have_link "Back"
    end

    it "can fill in and submit the event from, which triggers an email" do
      event = FactoryBot.build(:event, location: @location, technology: @technology)

      fill_in "event_title", with: event.title
      find('#event_location_id').find(:css, 'option[value="' + @location.id.to_s+ '"]').select_option
      fill_in "event_start_time", with: event.start_time
      fill_in "event_end_time", with: event.end_time
      fill_in "event_description", with: "Capybara did this"
      find('#event_technology_id').find(:css, 'option[value="' + @technology.id.to_s + '"]').select_option
      fill_in "event_min_leaders", with: event.min_leaders
      fill_in "event_max_leaders", with: event.max_leaders
      fill_in "event_min_registrations", with: event.min_registrations
      fill_in "event_max_registrations", with: event.max_registrations

      first_count = Delayed::Job.count

      click_button "Submit"

      expect(page).to have_content "Upcoming Builds"
      saved_event = Event.last
      expect(saved_event.title).to eq event.title
      expect(saved_event.location).to eq event.location
      expect(saved_event.technology).to eq event.technology

      second_count = Delayed::Job.count
      expect(second_count).to eq first_count + 1
    end
  end
end
