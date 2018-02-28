require 'rails_helper'

RSpec.describe "Restoring a cancelled event", type: :system do

  before :each do
    sign_in FactoryBot.create(:admin)
    @event = FactoryBot.create(:event)
    5.times { FactoryBot.create(:registration, event: @event, guests_registered: Random.rand(0..2)) }
    @event.destroy

    visit cancelled_events_path
  end

  after :all do
    clean_up!
  end

  it "requires an event to be deleted first" do
    visit "/"
    expect(page).to have_link "Manage Cancelled Events"

    expect(@event.deleted_at).to_not be nil

    Registration.all.each do |r|
      expect(r.deleted_at).to_not be nil
    end

    visit cancelled_events_path

    expect(page).to have_content "Cancelled Builds"
    expect(page).to have_content @event.title
    expect(page).to have_link "Restore Event & Registrations"
    expect(page).to have_link "Restore Event Only"
  end

  it "without restoring the associated registrations" do
    click_link "Restore Event Only"

    expect(page).to have_content "Event restored but not registrations."
    expect(page).to have_content "Upcoming Builds"

    @event.reload
    expect(@event.deleted_at).to be nil
    Registration.all.each do |r|
      expect(r.deleted_at).to_not be nil
    end
  end

  it "while restoring the associated registrations" do
    click_link "Restore Event & Registrations"

    expect(page).to have_content "Event and associated registrations restored."
    expect(page).to have_content "Upcoming Builds"

    @event.reload
    expect(@event.deleted_at).to be nil
    Registration.all.each do |r|
      expect(r.deleted_at).to be nil
    end    
  end

  it "stays on the cancelled events page if there are more cancelled events" do
    @event2 = FactoryBot.create(:event)
    2.times { FactoryBot.create(:registration, event: @event2, guests_registered: Random.rand(0..2)) }
    @event2.destroy

    link_id = "event_only_" + @event.id.to_s
    click_link link_id

    expect(page).to have_content "Event restored but not registrations."
    expect(page).to have_content "Cancelled Builds"
    expect(page).to have_css("div#event_cancelled_" + @event2.id.to_s)
    expect(page).not_to have_css("div#event_cancelled_" + @event.id.to_s)
  end

end