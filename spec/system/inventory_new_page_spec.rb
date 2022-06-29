# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a new inventory', type: :system do
  context 'when visiting the page as' do
    it 'anon users redirects to sign_in page' do
      visit new_inventory_path

      expect(page).to have_content 'You need to sign in first'
      expect(page).to have_content 'Sign in'
    end

    it 'builders redirects to home page' do
      sign_in create(:user)

      visit new_inventory_path

      expect(page).to have_content "You don't have permission"
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'leaders redirects to home page' do
      sign_in create(:leader)

      visit new_inventory_path

      expect(page).to have_content "You don't have permission"
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'inventory users shows the page' do
      sign_in create(:inventoryist)
      visit new_inventory_path

      expect(page).to have_content "Create a new manual inventory"
    end

    it 'users who receive inventory redirects to home page' do
      sign_in create(:user, send_inventory_emails: true)
      visit new_inventory_path

      expect(page).to have_content "You don't have permission"
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'admins shows the page' do
      sign_in create(:admin)
      visit new_inventory_path

      expect(page).to have_content "Create a new manual inventory"
      expect(page).to have_css('input#inventory_date')
      expect(page).to have_button 'Create Inventory'
    end

    it 'scheduler redirects to home page' do
      sign_in create(:scheduler)
      visit new_inventory_path

      expect(page).to have_content "You don't have permission"
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'data manager shows the page' do
      sign_in create(:data_manager)
      visit new_inventory_path

      expect(page).to have_content "Create a new manual inventory"
    end
  end

  context 'when the URL has' do
    before :each do
      sign_in create(:admin)
    end

    context 'no parameter' do
      before :each do
        visit new_inventory_path
      end

      it 'establishes a manual inventory' do
        expect(page).to have_css("input#inventory_manual[value='true']", visible: false)
        expect(page).to have_css("input#inventory_receiving[value='false']", visible: false)
        expect(page).to have_css("input#inventory_shipping[value='false']", visible: false)
      end

      it 'shows the technology selection options' do
        expect(page).to have_content 'Select technologies to inventory:'
      end
    end

    context '?type=manual' do
      before :each do
        visit new_inventory_path(type: 'manual')
      end

      it 'establishes a manual inventory' do
        expect(page).to have_css("input#inventory_manual[value='true']", visible: false)
        expect(page).to have_css("input#inventory_receiving[value='false']", visible: false)
        expect(page).to have_css("input#inventory_shipping[value='false']", visible: false)
      end

      it 'shows the technology selection options' do
        expect(page).to have_content 'Select technologies to inventory:'
      end
    end

    context '?type=receiving' do
      before :each do
        visit new_inventory_path(type: 'receiving')
      end

      it 'establishes a receiving inventory' do
        expect(page).to have_css("input#inventory_manual[value='false']", visible: false)
        expect(page).to have_css("input#inventory_receiving[value='true']", visible: false)
        expect(page).to have_css("input#inventory_shipping[value='false']", visible: false)
      end

      it 'shows the technology selection options' do
        expect(page).to have_content 'Select technologies to inventory:'
      end
    end

    context '?type=shipping' do
      before :each do
        visit new_inventory_path(type: 'shipping')
      end

      it 'establishes a shipping inventory' do
        expect(page).to have_css("input#inventory_manual[value='false']", visible: false)
        expect(page).to have_css("input#inventory_receiving[value='false']", visible: false)
        expect(page).to have_css("input#inventory_shipping[value='true']", visible: false)
      end

      it "shows the technology selection options" do
        expect(page).to have_content 'Select technologies to inventory:'
      end
    end
  end

  context 'is possible' do
    let(:technologies) { create_list :technology, 4 }
    let(:parts) { create_list :part, 7 }
    let(:components) { create_list :component, 4 }
    let(:materials) { create_list :material, 2 }

    it 'by clicking the button' do
      technologies
      parts
      components
      materials

      sign_in create(:admin)
      visit new_inventory_path

      expect { click_button 'Create Inventory' }
        .to change { Inventory.all.count }
        .by(1)

      expect(page).to have_content('The inventory has been created.')
      expect(page).to have_css('div#inventory_edit')
    end

    context 'while skipping some technologies' do
      it 'and then clicking the button' do
        technologies
        parts
        components
        materials
        Assembly.create(item: Part.first, combination: Technology.first)
        Assembly.create(item: Component.first, combination: Technology.first)
        Assembly.create(item: Material.first, combination: Technology.first)

        QuantityAndDepthCalculationJob.perform_now

        sign_in create(:admin)
        visit new_inventory_path

        # clicking un-checks the box which is checked by default
        find("input[value=#{Technology.second.id}]").click
        find("input[value=#{Technology.third.id}]").click

        click_button 'Create Inventory'

        # Should have skipped creating 1 of each item (16 counts would be everything)
        expect(page).to have_content('The inventory has been created.')
        expect(page).to have_css('div#inventory_edit')

        expect(Inventory.latest.counts.size).to eq 5
      end
    end
  end
end
