require 'rails_helper'

RSpec.describe "Visiting Events", type: :system do

  context "in the future that are" do
    it "public can be visited" do
      event = FactoryBot.create(:event, is_private: false)

      visit event_path event

      expect(page).to have_content event.full_title
    end

    it "private can be visited" do
      event = FactoryBot.create(:event, is_private: true)

      visit event_path event

      expect(page).to have_content event.full_title
    end
  end

  context "past tense, anon user" do
    event = FactoryBot.create(:past_event)

    it "can't be visited" do
      visit event_path event

      expect(page).to have_content "You need to sign in first"
      expect(page).to have_content "Sign in"
    end
  end

  context "past tense, builder, regardless of registered" do
    event = FactoryBot.create(:past_event)
    builder = FactoryBot.create(:user)

    it "can't be visited" do
      sign_in builder
      visit event_path event

      expect(page).to have_content "You don't have permission"
      expect(page).to have_content "Want a custom build event for your group?"
      expect(page).to have_content "Upcoming Builds"
    end
  end

  context "past tense, leader, not registered" do
    event = FactoryBot.create(:past_event)
    leader = FactoryBot.create(:leader)

    it "can't be visited" do
      sign_in leader
      visit event_path event

      expect(page).to have_content "You don't have permission"
      expect(page).to_not have_content "Want a custom build event for your group?"
      expect(page).to have_content "Upcoming Builds"
    end
  end

  context "past tense, leader, registered" do
    event = FactoryBot.create(:past_event)
    leader = FactoryBot.create(:leader, signed_waiver_on: Faker::Time.backward(90) )
    registration = FactoryBot.create(:registration_leader, event: event, user: leader)

    it "can be visited" do
      leader.technologies << event.technology
      leader.save

      sign_in leader
      registration.save
      visit event_path event

      expect(page).to have_content event.full_title
      expect(page).to have_content "You're Registered!"
      expect(page).to have_content leader.name
      expect(page).to have_link "Change/Cancel Registration"
    end
  end

  context "past tense, admin, regardless of registration" do
    event = FactoryBot.create(:past_event)
    admin = FactoryBot.create(:admin, signed_waiver_on: Faker::Time.backward(90) )
    registration = FactoryBot.build(:registration_leader, event: event, user: admin)

    it "can be visited" do
      sign_in admin
      visit event_path event

      expect(page).to have_content event.full_title
      expect(page).to have_content admin.name
      expect(page).to have_field "registration_accommodations"

      expect(page).to_not have_content "You're Registered!"
      expect(page).to_not have_link "Change/Cancel Registration"

      registration.save
      visit event_path event

      expect(page).to have_content event.full_title
      expect(page).to have_content "You're Registered!"
      expect(page).to have_content admin.name
      expect(page).to have_link "Change/Cancel Registration"
    end
  end

  context "future tense, anon user" do
    event = FactoryBot.create(:event)

    it "can be visited" do
      visit event_path event

      expect(page).to have_content event.full_title
      expect(page).to have_field "registration_user_fname"
      expect(page).to have_field "registration_accept_waiver"
      expect(page).to have_button "Register"
    end
  end

  # next 2 shouldn't have register as leader checkbox

  context "future tense, builder, not registered" do
    event = FactoryBot.create(:event)
    builder = FactoryBot.create(:user)

    it "can be visited" do
      sign_in builder
      visit event_path event

      expect(page).to have_content event.full_title
      expect(page).to have_field "registration_accept_waiver"
      expect(page).to have_button "Register"

      expect(page).to_not have_field "registration_user_fname"
      expect(page).to_not have_field "registration_leader"
    end
  end

  context "future tense, builder, registered" do
    event = FactoryBot.create(:event)
    builder = FactoryBot.create(:user, signed_waiver_on: Faker::Time.backward(90) )
    registration = FactoryBot.create(:registration_leader, event: event, user: builder)

    it "can be visited" do
      registration.save
      sign_in builder
      visit event_path event

      expect(page).to have_content event.full_title
      expect(page).to have_content "You're Registered!"
      expect(page).to have_content builder.name
      expect(page).to have_link "Change/Cancel Registration"

      expect(page).to_not have_field "registration_leader"
    end
  end

  context "future tense, leader, not registered" do
    event = FactoryBot.create(:event)
    leader = FactoryBot.create(:leader)

    it "can be visited" do
      leader.technologies << event.technology
      leader.save
      sign_in leader
      visit event_path event

      expect(page).to have_content event.full_title
      expect(page).to have_content leader.name
      expect(page).to have_field "registration_accept_waiver"
      expect(page).to have_field "registration_leader"
      expect(page).to have_button "Register"
    end
  end

  context "future tense, leader, registered" do
    event = FactoryBot.create(:event)
    leader = FactoryBot.create(:leader, signed_waiver_on: Faker::Time.backward(90) )
    registration = FactoryBot.create(:registration_leader, event: event, user: leader)

    it "can be visited" do
      sign_in leader
      registration.save
      visit event_path event

      expect(page).to have_content event.full_title
      expect(page).to have_content "You're Registered!"
      expect(page).to have_content leader.name
      expect(page).to have_link "Change/Cancel Registration"

      expect(page).to_not have_field "registration_leader"
    end
  end

  context "future tense, admin, not registered" do
    event = FactoryBot.create(:event)
    admin = FactoryBot.create(:admin )

    it "can be visited" do
      admin.technologies << event.technology
      admin.save
      sign_in admin
      visit event_path event

      expect(page).to have_content event.full_title
      expect(page).to have_content admin.name
      expect(page).to have_field "registration_accommodations"
      expect(page).to have_field "registration_leader"

      expect(page).to_not have_content "You're Registered!"
      expect(page).to_not have_link "Change/Cancel Registration"
    end
  end

  context "future tense, admin, registered" do
    event = FactoryBot.create(:event)
    admin = FactoryBot.create(:admin, signed_waiver_on: Faker::Time.backward(90) )
    registration = FactoryBot.build(:registration_leader, event: event, user: admin)

    it "can be visited" do
      admin.technologies << event.technology
      admin.save
      sign_in admin
      registration.save
      visit event_path event

      expect(page).to have_content event.full_title
      expect(page).to have_content "You're Registered!"
      expect(page).to have_content admin.name
      expect(page).to have_link "Change/Cancel Registration"

      expect(page).to_not have_field "registration_leader"
    end
  end
end