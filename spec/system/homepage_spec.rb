require 'rails_helper'

RSpec.describe "Homepage", type: :system do

  it "goes to the homepage" do
    visit "/"
    expect(page).to have_content 'Want a custom build event for your group?'
  end
end