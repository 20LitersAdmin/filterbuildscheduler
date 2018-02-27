require 'rails_helper'

RSpec.describe "To create an event report", type: :system, js: true do
  before :each do
    sign_in FactoryBot.create(:admin)
  end

  after :all do
    clean_up!
  end

  context "by visiting the Event#show page," do
    
    it "future events dont include an event report section" do
      event = FactoryBot.create(:event)
      visit event_path event

      expect(page).to have_content event.title
      expect(page).to have_content "Register"

      expect(page).not_to have_content "Report"
      expect(page).not_to have_field "event_technologies_built"
      expect(page).not_to have_field "event_boxes_packed"
      expect(page).not_to have_field "event_attendance"
      expect(page).not_to have_content "Registration-based attendance:"
      expect(page).not_to have_button "Submit Report"
      expect(page).not_to have_button "Submit Report & Email Results"
    end

    it "past events have an event report section" do
      event = FactoryBot.create(:past_event)
      visit event_path event

      expect(page).to have_content event.title
      expect(page).to have_content "Register"
      expect(page).to have_content "Report"
      expect(page).to have_field "event_technologies_built"
      expect(page).to have_field "event_boxes_packed"
      expect(page).to have_field "event_attendance"
      expect(page).to have_content "Registration-based attendance:"
      expect(page).to have_button "Submit Report"

      # no registrations means no option to email results
      expect(page).not_to have_button "Submit Report & Email Results"

      2.times { FactoryBot.create(:registration, event: event) }
      visit event_path event

      expect(page).to have_button "Submit Report & Email Results"
    end
  end

  context "fill out the form" do
    before :each do
      @event = FactoryBot.create(:past_event)
      5.times { FactoryBot.create(:registration, event: @event, guests_registered: Random.rand(0..2)) }
      visit event_path @event
    end

    it "with some technology stats" do
      fill_in "event_technologies_built", with: 450
      fill_in "event_boxes_packed", with: 4

      click_button "Submit Report"

      expect(page).to have_content "Event updated."
      @event.reload
      expect(@event.technologies_built).to eq 450
      expect(@event.boxes_packed).to eq 4
      expect(@event.attendance).to eq 0
      expect(@event.emails_sent).to be_falsey
    end

    context "with attendee information" do

      it "which auto-counts the total attendance" do
        expect(page).to have_css("div.event_registrations_attended", count: 5)
        expect(page).to have_field("event_attendance", with: "0")

        check "event_registrations_attributes_0_attended"

        expect(page).to have_field("event_attendance", with: "1")

        fill_in "event_registrations_attributes_1_guests_attended", with: 2
        check "event_registrations_attributes_1_attended"

        expect(page).to have_field("event_attendance", with: "4")

        uncheck "event_registrations_attributes_0_attended"

        expect(page).to have_field("event_attendance", with: "3")
      end

      it "which allows for select-all / un-select all" do
        expect(page).to have_css("div.event_registrations_attended", count: 5)
        expect(page).to have_field("event_attendance", with: "0")

        click_link "btn_check_all"

        expect(page).to have_field("event_attendance", with: "5")

        click_link "btn_uncheck_all"

        expect(page).to have_field("event_attendance", with: "0")
      end
    end

    it "and submit it without sending an email" do
      fill_in "event_technologies_built", with: 250
      fill_in "event_boxes_packed", with: 2
      click_link "btn_check_all"

      expect(page).to have_field("event_attendance", with: "5")

      first_count = ActionMailer::Base.deliveries.count

      click_button "Submit Report"

      second_count = ActionMailer::Base.deliveries.count

      expect(page).to have_content "Event updated."
      @event.reload
      expect(@event.complete?).to eq true
      expect(@event.technologies_built).to eq 250
      expect(@event.boxes_packed).to eq 2
      expect(@event.emails_sent).to eq false
      expect(second_count).to eq first_count
    end

    it "and submit it while sending an email" do
      fill_in "event_technologies_built", with: 350
      fill_in "event_boxes_packed", with: 3
      click_link "btn_check_all"

      expect(page).to have_field("event_attendance", with: "5")

      first_count = Delayed::Job.count

      click_button "Submit Report & Email Results"

      second_count = Delayed::Job.count

      expect(page).to have_content "Event updated."
      expect(page).to have_content "Attendees notified of results."
      @event.reload

      expect(page).to have_content "Event updated."
      @event.reload
      expect(@event.complete?).to eq true
      expect(@event.technologies_built).to eq 350
      expect(@event.boxes_packed).to eq 3
      expect(@event.emails_sent).to eq true
      expect(second_count).to eq first_count + 5
    end

    it "and submit it to create an inventory" do
      @event.technology.components << FactoryBot.create(:component_ct)
      @event.technology.save

      fill_in "event_technologies_built", with: 350
      fill_in "event_boxes_packed", with: 3

      click_button "Submit Report"

      expect(page).to have_content "Event updated."
      expect(page).to have_content "Inventory created."
      expect(Inventory.last.event).to eq @event
      count_in_question = Count.where(component: @event.technology.primary_component).last
      expect(count_in_question.loose_count).to eq 350
      expect(count_in_question.unopened_boxes_count).to eq 3
    end
  end
end