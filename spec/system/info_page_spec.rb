# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Info page', type: :system, js: true do
  before :each do
    visit info_path
  end

  it 'can be visited' do
    expect(page).to have_css('div#info-page')
  end

  context 'accordion div' do
    it 'can be clicked' do
      click_link('how')

      expect(page).to have_css('div#collapseHow.in')
      expect(page).not_to have_css('div#collapseWhat.in')
    end
  end
end
