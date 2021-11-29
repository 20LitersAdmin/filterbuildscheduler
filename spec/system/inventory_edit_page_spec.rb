# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Inventory edit page', type: :system do
  let(:inventory) { create :inventory }

  context 'when there are no counts' do
    it 'redirects to show page' do
      sign_in create(:admin)
      visit edit_inventory_path inventory

      expect(page).to have_content "#{inventory.name} Inventory"
      expect(current_path).to eq inventory_path(inventory)
    end
  end

  context 'when visited by' do
    let(:count) { create :count, inventory: inventory }

    it 'anon users redirects to sign_in page' do
      count
      visit edit_inventory_path inventory

      expect(page).to have_content 'You need to sign in first'
      expect(page).to have_content 'Sign in'
    end

    it 'builders redirects to home page' do
      count
      sign_in create(:user)
      visit edit_inventory_path inventory

      expect(page).to have_content "You don't have permission"
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'leaders redirects to home page' do
      count
      sign_in create(:leader)
      visit edit_inventory_path inventory

      expect(page).to have_content "You don't have permission"
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'users who receive inventory emails redirects to home page' do
      count
      sign_in create(:user, send_inventory_emails: true)
      visit edit_inventory_path inventory

      expect(page).to have_content "You don't have permission"
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'data manager shows the page' do
      count
      sign_in create(:data_manager)
      visit edit_inventory_path inventory

      expect(page).to have_content "Edit #{inventory.name}"
    end

    it 'inventory users shows the page' do
      count
      sign_in create(:inventoryist)
      visit edit_inventory_path inventory

      expect(page).to have_content "Edit #{inventory.name}"
    end

    it 'admins shows the page' do
      count
      sign_in create(:admin)

      visit edit_inventory_path inventory

      expect(page).to have_content "Edit #{inventory.name}"
    end
  end

  context 'has filters' do
    let(:count) { create :count, inventory: inventory }

    it 'on the page' do
      count
      sign_in create(:admin)
      visit edit_inventory_path inventory

      expect(page).to have_content inventory.name
      expect(page).to have_content 'Filters:'
      expect(page).to have_button 'Show All'
      expect(page).to have_button 'Uncounted'
      expect(page).to have_button 'Partial'
      expect(page).to have_button 'Counted'
      expect(page).to have_css('input#search')
    end
  end

  context 'when counting items, users can', js: true do
    before :each do
      @inventory = create :inventory
      @user = create :admin
      sign_in @user

      [['technology 1', 'tech1'], ['technology 2', 'tech2'], ['technology 3', 'tech3']].each do |ary|
        tech = create :technology, name: ary[0], short_name: ary[1], list_worthy: true
        create :count_tech, item: tech, inventory: @inventory, loose_count: 0, unopened_boxes_count: 0
      end

      # create 4 parts w counts
      create_list :count, 4, inventory: @inventory, loose_count: 0, unopened_boxes_count: 0

      # create 4 components w counts
      create_list :count_comp, 4, inventory: @inventory, loose_count: 0, unopened_boxes_count: 0

      visit edit_inventory_path @inventory
    end

    fit 'search' do
      expect(page).to have_content "Edit #{inventory.name}"

      fill_in 'search', with: Part.second.name

      expect(page).to have_content Part.second.name
      expect(page).to have_css("div[data-item-uid=#{Part.first.uid}]", visible: false)
      expect(page).to have_css("div[data-item-uid=#{Part.third.uid}]", visible: false)
      expect(page).to have_css("div[data-item-uid=#{Component.first.uid}]", visible: false)
      expect(page).to have_css("div[data-item-uid=#{Component.second.uid}]", visible: false)

      click_button 'Show All'

      fill_in 'search', with: Component.first.name

      expect(page).to have_content Component.first.name
      expect(page).to have_css("div[data-item-uid=#{Part.first.uid}]", visible: false)
      expect(page).to have_css("div[data-item-uid=#{Part.third.uid}]", visible: false)
      expect(page).to have_css("div[data-item-uid=#{Component.fourth.uid}]", visible: false)
      expect(page).to have_css("div[data-item-uid=#{Component.second.uid}]", visible: false)
    end

    fit 'filter by status' do
      @count1 = Count.first
      @count1.update(user: @user)

      @count2 = Count.second
      @count2.update(partial_box: true)

      @count3 = Count.third
      @count3.update(partial_loose: true)

      # refresh the page, wait for it to load
      visit edit_inventory_path @inventory
      expect(page).to have_content "Edit #{inventory.name}"

      click_button 'Uncounted'

      expect(page).to have_css("div#count_#{Count.first.id}", visible: false)
      expect(page).to have_css("div#count_#{Count.second.id}", visible: false)
      expect(page).to have_css("div#count_#{Count.third.id}", visible: false)
      expect(page).to have_content Count.fourth.item.name

      click_button 'Show All'
      click_button 'Counted'

      expect(page).to have_content Count.first.item.name
      expect(page).to have_css("div#count_#{Count.second.id}", visible: false)
      expect(page).to have_css("div#count_#{Count.third.id}", visible: false)

      click_button 'Show All'
      click_button 'Partial'

      expect(page).to have_css("div#count_#{Count.first.id}", visible: false)
      expect(page).to have_content Count.second.item.name
      expect(page).to have_content Count.third.item.name
    end

    # HERE
    # All submissions should hit CountUpdate.new
    # Partials: button text ends in 'Count'
    # Full submissions: button text is 'Edit'
    pending 'submit a partial box count'

    pending 'submit a partial loose count'

    pending 'submit a full count'

    pending 'finalize the inventory' do
      allow(CountTransferJob).to receive(:perform_later).with(inventory).and_call_original

      click_link 'Finalize'

      expect(CountTransferJob).to receive(:perform_later).with(inventory)

      click_button 'Finalize Inventory'

      expect(page).not_to have_content 'Current Inventory:'
      expect(page).to have_content 'Inventory Counts:'
    end
  end
end
