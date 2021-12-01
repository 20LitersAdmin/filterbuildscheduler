# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Combinations#edit' do
  before do
    @tech = create :technology
    create_list :assembly_tech, 4, combination: @tech
  end

  context 'when visited by a' do
    it 'anon user, it redirects to sign-in page' do
      visit edit_combination_path(@tech.uid)

      expect(page).to have_content 'You need to sign in first'
      expect(page).to have_content 'Sign in'
    end

    it 'builder, it redirects to home page' do
      sign_in create :user
      visit edit_combination_path(@tech.uid)

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'leader, it redirects to home page' do
      sign_in create :leader
      visit edit_combination_path(@tech.uid)

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'inventoryist, it shows the page' do
      sign_in create :inventoryist
      visit edit_combination_path(@tech.uid)

      expect(page).to have_content 'EDIT Assemblies for'
    end

    it 'scheduler, it redirects to home page' do
      sign_in create :scheduler
      visit edit_combination_path(@tech.uid)

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'data_manager, it shows the page' do
      sign_in create :data_manager
      visit edit_combination_path(@tech.uid)

      expect(page).to have_content 'EDIT Assemblies for'
    end

    it 'admin, it shows the page' do
      sign_in create :admin
      visit edit_combination_path(@tech.uid)

      expect(page).to have_content 'EDIT Assemblies for'
    end
  end

  context 'allows an authorized user to', js: true do
    before do
      sign_in create :admin

      visit edit_combination_path(@tech.uid)
      expect(page).to have_content 'EDIT Assemblies for'
    end

    it 'create an assembly' do
      item = create :component, name: 'FactoryBot comp'

      click_link 'New'

      expect(page).to have_content 'Create a new Assembly'

      fill_in 'assembly_item_search', with: item.name

      find('#assembly_quantity').click

      expect(page).to have_css('select#assembly_item_id', wait: 3)

      select item.name, from: 'assembly_item_id'

      fill_in 'assembly_quantity', with: 2

      click_submit

      expect(page).to have_content('Assembly created!', wait: 3)

      expect(Assembly.last.quantity).to eq 2
      expect(Assembly.last.item).to eq item
      expect(Assembly.last.combination).to eq @tech
    end

    it 'edit an assembly' do
      assembly = @tech.assemblies.first

      within("tr#assembly_#{assembly.id}") { click_link 'Edit' }

      expect(page).to have_content assembly.name_long

      fill_in 'assembly_quantity', with: 5

      click_submit

      expect(page).to have_content 'Assembly updated!'

      expect(assembly.reload.quantity).to eq 5
    end

    it 'delete an assembly' do
      assembly = @tech.assemblies.first

      within("tr#assembly_#{assembly.id}") do
        accept_confirm { click_link 'Delete' }
      end

      expect(page).to have_content 'Assembly deleted.'

      expect { assembly.reload }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
