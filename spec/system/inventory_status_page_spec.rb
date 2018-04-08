require 'rails_helper'

RSpec.describe "Inventory status page", type: :system, js: true do
  after :all do
    clean_up!
  end

  context "when visited by" do

    it "anon users redirects to sign_in page" do
      visit status_inventories_path

      expect(page).to have_content "You need to sign in first"
      expect(page).to have_content "Sign in"
    end

    it "builders redirects to home page" do
      sign_in FactoryBot.create(:user)

      visit status_inventories_path

      expect(page).to have_content "You don't have permission"
      expect(page).to have_content "Upcoming Builds"
    end

    it "leaders shows the page" do
      sign_in FactoryBot.create(:leader)

      visit status_inventories_path

      expect(page).to have_content "Status"
    end
  end

  context "when visited by an admin or leader" do
    before :all do
      5.times do
        FactoryBot.create(:technology)
      end

      unworthy = Technology.last
      unworthy.update(monthly_production_rate: 0)

      Technology.all.each do |tech|
        parts = []
        comps = []
        mats = []

        3.times do
          parts << FactoryBot.create(:part)
          comps << FactoryBot.create(:component)
          mats << FactoryBot.create(:material)
        end

        parts.each do |part|
          FactoryBot.create(:tech_part, part: part, technology: tech)
        end

        comp_ct = FactoryBot.create(:component_ct)
        FactoryBot.create(:tech_comp, component: comp_ct, technology: tech)

        comps.each do |comp|
          FactoryBot.create(:tech_comp, component: comp, technology: tech)
        end

        mats.each do |mat|
          FactoryBot.create(:tech_mat, material: mat, technology: tech)
        end
      end

      inventory = FactoryBot.create(:inventory, completed_at: Time.now)

      #counts
      Part.all.each do |part|
        FactoryBot.create(:count_part, part: part, inventory: inventory)
      end

      Component.all.each do |comp|
        FactoryBot.create(:count_comp, component: comp, inventory: inventory)
      end

      Material.all.each do |mat|
        FactoryBot.create(:count_mat, material: mat, inventory: inventory)
      end

      FactoryBot.create(:event, start_time: Time.now + 15.days, end_time: Time.now + 15.days + 3.hours, item_goal: 143, technology: Technology.first )
      FactoryBot.create(:event, start_time: Time.now + 45.days, end_time: Time.now + 45.days + 3.hours, item_goal: 59, technology: Technology.second )
    end

    before :each do
      coin = Random.rand(0..1)

      if coin == 0
        sign_in FactoryBot.create(:admin)
      else
        sign_in FactoryBot.create(:leader)
      end

      visit status_inventories_path
    end

    it "shows the page" do
      expect(Count.all.count).to eq 50

      expect(page).to have_content "Status"
      expect(page).to have_content "CSV"
    end

    it "shows a list of technologies with a monthly_production_rate > 0" do
      expect(page).to have_css("h4.tech-title", count: 4)
      expect(page).to have_content(Technology.first.name)
      expect(page).to have_css("#tech_#{Technology.second.id.to_s}")
      expect(page).to_not have_css("#tech_#{Technology.last.id.to_s}")
    end

    fit "shows how many technologies are currently available" do
      expect(page).to have_css("td.tech-produceable", count: 5)
      # save_and_open_page
      # binding.pry
    end

    it "shows how many technologies can be produced"

    it "takes upcoming events into account" do
      expect(page).to have_css("td.tech-event-goals", text: "0", count: 3)
      expect(page).to have_css("td.tech-event-goals", text: "143", count: 1)
      expect(page).not_to have_css("td.tech-event-goals", text: "59")
    end
  end

end