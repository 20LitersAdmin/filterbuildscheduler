# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Selected labels page', type: :system do
  before do
    sign_in create(:admin)

    3.times do
      create(:part)
      create(:material)
      create(:component)
      create(:technology)
    end

    # first go to /labels, select them all then click 'Submit'
    visit labels_path
    all('input[type=checkbox]').each { |cb| cb.click }
    find('input[type="submit"]', match: :first).click
  end

  it 'displays a page with labels' do
    expect(page).to have_current_path('/labels_select')
    expect(page).to have_content 'Printing instructions:'
    expect(page).to have_css 'div.label-4x2', count: 120
  end

  it 'displays 10 labels per item' do
    expect(page).to have_current_path('/labels_select')
    expect(page).to have_content(Part.first.uid).exactly(10).times
    expect(page).to have_content(Part.second.uid).exactly(10).times
    expect(page).to have_content(Part.third.uid).exactly(10).times
    expect(page).to have_content(Material.first.uid).exactly(10).times
    expect(page).to have_content(Material.second.uid).exactly(10).times
    expect(page).to have_content(Material.third.uid).exactly(10).times
    expect(page).to have_content(Component.first.uid).exactly(10).times
    expect(page).to have_content(Component.second.uid).exactly(10).times
    expect(page).to have_content(Component.third.uid).exactly(10).times
    expect(page).to have_content(Technology.first.uid).exactly(10).times
    expect(page).to have_content(Technology.second.uid).exactly(10).times
    expect(page).to have_content(Technology.third.uid).exactly(10).times
  end

  it 'displays the print navbar' do
    expect(page).to have_current_path('/labels_select')
    expect(page).to have_link 'Print'
  end
end
