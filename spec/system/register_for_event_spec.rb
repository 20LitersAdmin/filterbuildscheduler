require 'rails_helper'

RSpec.describe "Register for Event", type: :system do
  # Events are always in the past, right now. Check with event_spec to see why.
  let(:event) { create :event }

  context "logged in user" do
    
  end

  context "anon user" do

    fit "loads the event" do
      visit event_path(event)
      expect(page).to have_content event.title
    end

  end

  context "admin registering someone else" do

  end

end