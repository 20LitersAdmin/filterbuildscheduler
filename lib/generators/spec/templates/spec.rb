require 'rails_helper'

RSpec.describe "<%= human_string %>", type: <%= ":" + spec_type %> do
  before :each do
  end

  after :all do
    clean_up!
  end

  context "when visited by" do

    fit "anon users redirects to sign_in page" do
      visit #path

      expect(page).to have_content "You need to sign in first"
      expect(page).to have_content "Sign in"
    end

    fit "builders redirects to home page" do
      sign_in FactoryBot.create(:user)

      visit #path

      expect(page).to have_content "You don't have permission"
      expect(page).to have_content "Upcoming Builds"
    end

    fit "leaders redirects to home page" do
      sign_in FactoryBot.create(:leader)

      visit #path

      expect(page).to have_content "You don't have permission"
      expect(page).to have_content "Upcoming Builds"
    end
  end

  context "when visited by an admin" do
    before :each do
      sign_in FactoryBot.create(:admin)
      visit #path
    end

    fit "shows ..." do
    end
  end

end