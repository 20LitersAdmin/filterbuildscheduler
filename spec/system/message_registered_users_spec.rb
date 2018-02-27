require 'rails_helper'

RSpec.describe "Email registered users:", type: :system do
  before :each do
    @event = FactoryBot.create(:event, max_registrations: 40)

    5.times do |n|
      FactoryBot.create(:registration, event: @event)
    end
  end

  after :all do
    clean_up!
  end


  context "anon user" do
    it "can't visit the messenger page" do
      visit messenger_event_registrations_path @event
      expect(page).to have_content "You need to sign in first"
      expect(page).to have_content "Sign in"
    end
  end

  context "builder" do
    it "can't visit the messenger page" do
      user = FactoryBot.create(:user)
      sign_in user
      visit messenger_event_registrations_path @event

      expect(page).to have_content "You don't have permission"
      expect(page).to have_content "Upcoming Builds"
    end
  end

  context "leader" do
    before :each do
      @user = FactoryBot.create(:leader)
      sign_in @user
      visit messenger_event_registrations_path @event
    end

    it "can visit the messenger page" do
      expect(page).to have_content "Send a message to all 5 builders?"
      expect(page).to have_field "subject"
      expect(page).to have_field "message"
      expect(page).to have_button "Send Message"
    end

    it "can fill out and submit the form" do
      fill_in "subject", with: "Leaders can send messages"
      fill_in "message", with: "My name is " + @user.name + "and I'm a leader."
      click_button "Send Message"

      expect(page).to have_content "Registrations for " + @event.full_title
    end
  end

  context "admin" do
    before :each do
      @user = FactoryBot.create(:admin, send_notification_emails: true)
      sign_in @user
      visit messenger_event_registrations_path @event
    end

    it "can visit the messenger page" do
      expect(page).to have_content "Send a message to all"
      expect(page).to have_field "subject"
      expect(page).to have_field "message"
      expect(page).to have_button "Send Message"
    end

    it "can fill out and submit the form, which queues up some emails" do
      fill_in "subject", with: "Admins can send messages"
      fill_in "message", with: "My name is " + @user.name + " and I'm an admin."

      first_count = Delayed::Job.count

      click_button "Send Message"

      expect(page).to have_content "Registrations for " + @event.full_title

      second_count = Delayed::Job.count

      expect(second_count).to eq first_count + 6
    end
  end



end