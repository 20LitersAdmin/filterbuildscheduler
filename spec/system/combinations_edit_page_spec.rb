# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Combinations#edit allows an Admin to', js: true do
  before do
    @tech = create :technology
    create_list :assembly_tech, 4, combination: @tech

    sign_in create :admin

    visit edit_combination_path(@tech.uid)
    expect(page).to have_content 'EDIT Assemblies for'
  end

  it 'create an assembly' do
    item = create :component

    click_link 'New'

    expect(page).to have_content 'Create a new Assembly'

    fill_in 'assembly_item_search', with: item.name

    find('#assembly_quantity').click

    expect(page).to have_css 'select#assembly_item_id'

    select item.name, from: 'assembly_item_id'

    fill_in 'assembly_quantity', with: 2

    click_submit

    expect(page).to have_content 'Assembly created!'

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
