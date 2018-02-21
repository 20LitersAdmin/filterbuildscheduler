require 'rails_helper'

RSpec.describe "Printing an attendance list", type: :system do
  before :each do
    @event = FactoryBot.create(:event, max_registrations: 5)
    5.times { FactoryBot.create(:registration, event: @event, guests_registered: 0) }
    2.times { FactoryBot.create(:registration_leader, event: @event, guests_registered: 0) }
  end

  after :all do
    clean_up!
  end

  context "when current_user" do
    let(:admin) { create :admin }
    let(:leader) { create :leader }
    let(:builder) { create :user }

    it "is anon is not allowed" do
      visit attendance_event_path @event
      expect(page).to have_content "You need to sign in first"
    end

    it "is builder is not allowed" do
      sign_in builder
      visit attendance_event_path @event
      expect(page).to have_content "You don't have permission"
    end

    it "is leader is allowed" do
      sign_in leader
      visit attendance_event_path @event
      expect(page).to have_content "Filter Build Attendance on " + @event.format_time_range
    end

    it "is admin is allowed" do
      sign_in admin
      visit attendance_event_path @event
      expect(page).to have_content "Filter Build Attendance on " + @event.format_time_range
    end
  end

  it "from a webpage" do
    sign_in FactoryBot.create(:admin)
    visit attendance_event_path @event

    expect(page).to have_content "Filter Build Attendance on " + @event.format_time_range
    expect(page).to have_link "print_btn"

    expect(page).to have_css("table.attendance-list tbody tr", count: 10)    
  end

end