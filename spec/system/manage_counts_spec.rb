require 'rails_helper'

RSpec.describe "Managing counts:", type: :system, js: true do
  before :each do
    @inventory = FactoryBot.create(:inventory)
    tech = FactoryBot.create(:technology)
    part = FactoryBot.create(:part)
    FactoryBot.create(:tech_part, part: part, technology: tech)
    @count = FactoryBot.create(:count_part, part: part, inventory: @inventory, loose_count: 18, unopened_boxes_count: 3 )
  end

  after :all do
    clean_up!
  end

  context "the page" do
    it "can't be visited by anon users" do
      visit edit_inventory_count_path @inventory, @count

      expect(page).to have_content "You need to sign in first"
      expect(page).to have_content "Sign in"
    end

    it "can't be visited by builders" do
      sign_in FactoryBot.create(:user)
      visit edit_inventory_count_path @inventory, @count

      expect(page).to have_content "You don't have permission"
      expect(page).to have_content "Upcoming Builds"
    end

    it "can't be visited by leaders" do
      sign_in FactoryBot.create(:leader)
      visit edit_inventory_count_path @inventory, @count

      expect(page).to have_content "You don't have permission"
      expect(page).to have_content "Upcoming Builds"
    end

    it "can be visited by inventory users" do
      sign_in FactoryBot.create(:user, does_inventory: true)
      visit edit_inventory_count_path @inventory, @count

      expect(page).to have_content @count.name
      expect(page).to have_content "Count inventory: Use positive numbers or 0"
    end

    it "can be visited by users who receive inventory" do
      sign_in FactoryBot.create(:user, send_inventory_emails: true)
      visit edit_inventory_count_path @inventory, @count

      expect(page).to have_content @count.name
      expect(page).to have_content "Count inventory: Use positive numbers or 0"
    end

    it "can be visited by admins" do
      sign_in FactoryBot.create(:admin)
      visit edit_inventory_count_path @inventory, @count

      expect(page).to have_content @count.name
      expect(page).to have_content "Count inventory: Use positive numbers or 0"
    end
  end

  context "the form can be" do
    before :each do
      @admin = FactoryBot.create(:admin)
      sign_in @admin
      visit edit_inventory_count_path @inventory, @count
    end

    it "fully submitted" do
      expect(@count.loose_count).to eq 18
      expect(@count.unopened_boxes_count).to eq 3

      fill_in "count_loose_count", with: 20
      fill_in "count_unopened_boxes_count", with: 2

      click_button "Submit"

      expect(page).to have_content "Count submitted"
      expect(page).to have_content @inventory.name

      @count.reload
      expect(@count.loose_count).to eq 20
      expect(@count.unopened_boxes_count).to eq 2
      expect(@count.user_id).to eq @admin.id
      expect(@count.partial_box).to eq false
      expect(@count.partial_loose).to eq false
    end

    it "partially submitted: loose" do
      expect(@count.loose_count).to eq 18
      expect(@count.unopened_boxes_count).to eq 3

      fill_in "count_loose_count", with: 34

      click_button "Partial Count: Loose"

      expect(page).to have_content "Count submitted"
      expect(page).to have_content @inventory.name

      @count.reload
      expect(@count.loose_count).to eq 34
      expect(@count.unopened_boxes_count).to eq 3
      expect(@count.user_id).to be nil
      expect(@count.partial_box).to eq false
      expect(@count.partial_loose).to eq true
    end

    it "partially submitted: box" do
      expect(@count.loose_count).to eq 18
      expect(@count.unopened_boxes_count).to eq 3

      fill_in "count_unopened_boxes_count", with: 8

      click_button "Partial Count: Boxes"

      expect(page).to have_content "Count submitted"
      expect(page).to have_content @inventory.name

      @count.reload
      expect(@count.loose_count).to eq 18
      expect(@count.unopened_boxes_count).to eq 8
      expect(@count.user_id).to be nil
      expect(@count.partial_box).to eq true
      expect(@count.partial_loose).to eq false
    end
  end

  it "the calculator can be used" do
    sign_in FactoryBot.create(:admin)
    visit edit_inventory_count_path @inventory, @count

    expect(page).to have_css("div#calculator")

    expect(find(:css, "#display").value).to eq ""

    click_button "3"
    click_button "+"
    click_button "5"

    expect(find(:css, "#display").value).to eq "3+5"

    click_button "="

    expect(find(:css, "#display").value).to eq "8"
  end

end