# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Technology items page', type: :system do
  before :each do
    @technology = FactoryBot.create(:technology)
    @title = "#{@technology.name} Item List:"
  end

  after :all do
    clean_up!
  end

  context 'when visited by' do
    it 'anon users redirects to sign-in page' do
      visit items_technology_path(@technology)

      expect(page).to have_content 'You need to sign in first'
      expect(page).to have_content 'Sign in'
    end

    it 'builders redirects to home page' do
      sign_in FactoryBot.create(:user)

      visit items_technology_path(@technology)

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'inventory users shows the page' do
      sign_in FactoryBot.create(:user, does_inventory: true)
      visit items_technology_path(@technology)

      expect(page).to have_content @title
    end

    it 'admins shows the page' do
      sign_in FactoryBot.create(:admin)
      visit items_technology_path(@technology)

      expect(page).to have_content @title
    end

    it 'users who receive inventory emails shows the page' do
      sign_in FactoryBot.create(:user, send_inventory_emails: true)
      visit items_technology_path(@technology)

      expect(page).to have_content @title
    end
  end

  context 'shows all' do
    before :each do
      sign_in FactoryBot.create(:admin)
    end

    context 'components' do
      before :each do
        @component = FactoryBot.create(:component)
        @component.extrapolate_technology_components.create(technology: @technology, required: true)
        @technology.reload
        @component.reload
      end

      it 'that aren\'t completed tech' do
        component_ct = FactoryBot.create(:component_ct)
        component_ct.extrapolate_technology_components.create(technology: @technology, required: true)
        component_ct.reload
        @technology.reload

        visit items_technology_path(@technology)

        expect(page).to have_content @component.name
        expect(page).not_to have_content component_ct.name
      end

      it 'and their child parts' do
        3.times { FactoryBot.create(:comp_part, component: @component) }

        @component.reload

        visit items_technology_path(@technology)

        expect(page).to have_content Part.first.name
        expect(page).to have_content Part.second.name
        expect(page).to have_content Part.third.name
      end
    end

    it 'parts' do
      3.times { FactoryBot.create(:tech_part, technology: @technology) }

      @technology.reload

      visit items_technology_path(@technology)

      expect(page).to have_content Part.first.name
      expect(page).to have_content Part.second.name
      expect(page).to have_content Part.third.name
    end

    it 'materials' do
      3.times { FactoryBot.create(:tech_mat, technology: @technology, required: true) }

      @technology.reload

      visit items_technology_path(@technology)

      expect(page).to have_content Material.first.name
      expect(page).to have_content Material.second.name
      expect(page).to have_content Material.third.name
    end
  end
end
