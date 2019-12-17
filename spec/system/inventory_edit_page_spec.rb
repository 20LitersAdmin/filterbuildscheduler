# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Inventory edit page', type: :system, js: true do
  before :each do
    @inventory = FactoryBot.create(:inventory)
    supplier = FactoryBot.create(:supplier)

    @tech1 = FactoryBot.create(:technology, name: 'Tech #1')
    @tech2 = FactoryBot.create(:technology, name: 'Tech #2')

    2.times { FactoryBot.create(:component_ct) }
    3.times { FactoryBot.create(:component) }
    Component.where('id % 2 = ?', '0').each do |c|
      FactoryBot.create(:tech_comp, component: c, technology: @tech1)
    end

    Component.where('id % 2 = ?', '1').each do |c|
      FactoryBot.create(:tech_comp, component: c, technology: @tech2)
    end

    4.times { FactoryBot.create(:part, supplier: supplier) }
    Part.where('id % 2 = ?', '0').each do |part|
      FactoryBot.create(:tech_part, part: part, technology: @tech1)
    end

    Part.where('id % 2 = ?', '1').each do |part|
      FactoryBot.create(:tech_part, part: part, technology: @tech2)
    end

    @user = FactoryBot.create(:admin)

    InventoriesController::CountCreate.new(@inventory, [], @user)
  end

  after :each do
    clean_up!
  end

  context 'when visited by' do
    it 'anon users redirects to sign_in page' do
      visit edit_inventory_path @inventory

      expect(page).to have_content 'You need to sign in first'
      expect(page).to have_content 'Sign in'
    end

    it 'builders redirects to home page' do
      sign_in FactoryBot.create(:user)
      visit edit_inventory_path @inventory

      expect(page).to have_content "You don't have permission"
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'inventory users shows the page' do
      sign_in FactoryBot.create(:user, does_inventory: true)
      visit edit_inventory_path @inventory

      expect(page).to have_content @inventory.name
    end

    it 'users who receive inventory emails shows the page' do
      sign_in FactoryBot.create(:user, send_inventory_emails: true)
      visit edit_inventory_path @inventory

      expect(page).to have_content @inventory.name
    end
  end

  context 'when visited by an admin' do
    before :each do
      sign_in FactoryBot.create(:admin)
      visit edit_inventory_path @inventory
    end

    it 'shows the page and filters' do
      expect(page).to have_content @inventory.name
      expect(page).to have_content 'Filters:'
      expect(page).to have_button 'Show All'
      expect(page).to have_button 'Uncounted'
      expect(page).to have_button 'Partial'
      expect(page).to have_button 'Counted'
      expect(page).to have_css('input#search')

      expect(page).to have_content Part.third.name
      expect(page).to have_content Component.fourth.name
    end

    it 'allows for filtering by search' do
      fill_in 'search', with: Part.second.name

      expect(page).to have_content Part.second.name
      expect(page).to have_css("div#count_#{Part.first.id}", visible: false)
      expect(page).to have_css("div#count_#{Part.third.id}", visible: false)
      expect(page).to have_css("div#count_#{Component.first.id}", visible: false)
      expect(page).to have_css("div#count_#{Component.second.id}", visible: false)

      click_button 'Show All'
      fill_in 'search', with: Component.first.name

      expect(page).to have_content Component.first.name
      expect(page).to have_css("div#count_#{Part.first.id}", visible: false)
      expect(page).to have_css("div#count_#{Part.third.id}", visible: false)
      expect(page).to have_css("div#count_#{Component.fourth.id}", visible: false)
      expect(page).to have_css("div#count_#{Component.second.id}", visible: false)
    end

    it 'allows for filtering by status' do
      @count1 = Count.first
      @count1.user = User.first
      @count1.save

      @count2 = Count.last
      @count2.user = User.first
      @count2.save

      @count3 = Count.second
      @count3.partial_box = true
      @count3.save

      @count4 = Count.third
      @count4.partial_loose = true
      @count4.save

      visit edit_inventory_path @inventory

      click_button 'Uncounted'

      expect(page).to have_content Count.second.name
      expect(page).to have_content Count.third.name
      expect(page).to have_css("div#count_#{Count.first.item.id}", visible: false)
      expect(page).to have_css("div#count_#{Count.last.item.id}", visible: false)

      click_button 'Show All'
      click_button 'Counted'

      expect(page).to have_content Count.first.name
      expect(page).to have_content Count.last.name
      expect(page).to have_css("div#count_#{Count.second.item.id}", visible: false)
      expect(page).to have_css("div#count_#{Count.third.item.id}", visible: false)

      click_button 'Show All'
      click_button 'Partial'

      expect(page).to have_content Count.second.name
      expect(page).to have_content Count.third.name
      expect(page).to have_css("div#count_#{Count.first.item.id}", visible: false)
      expect(page).to have_css("div#count_#{Count.last.item.id}", visible: false)
    end

    it 'can be finalized' do
      click_link 'Finalize'

      expect(InventoriesController::Extrapolate).to receive(:new).with(@inventory).and_call_original
      click_button 'Finalize Inventory'

      expect(page).to have_content 'Current Inventory:'
    end
  end
end
