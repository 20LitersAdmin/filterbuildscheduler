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
        3.times do
          @parts = FactoryBot.create(:part)
          @components = FactoryBot.create(:component)
          @materials = FactoryBot.create(:material)
        end

        tech.components << FactoryBot.create(:component_ct)

        tech.parts << @parts
        tech.components << @components
        tech.materials << @materials
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

    it "shows how many technologies are currently available"

    it "shows how many technologies can be produced"

    it "takes upcoming events into account"
  end

end