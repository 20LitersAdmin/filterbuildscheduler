# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Combinations#index' do
  let(:techs) { create_list :technology, 3, list_worthy: true }

  it 'shows a list of technologies' do
    techs
    sign_in create :admin
    visit combinations_path

    expect(page).to have_content 'Choose a Technology for a list of all items:'
    expect(page).to have_css('table#list_item_tbl tbody tr', count: 3)
  end
end
