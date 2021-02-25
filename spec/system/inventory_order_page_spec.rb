# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Order supplies page', type: :system, js: true do
  before :each do
    @inventory = FactoryBot.create(:inventory, completed_at: Time.now)
    @supplier1 = FactoryBot.create(:supplier)
    @supplier2 = FactoryBot.create(:supplier)

    tech = FactoryBot.create(:technology, monthly_production_rate: 20)

    3.times { FactoryBot.create(:part, supplier: @supplier1, minimum_on_hand: 20, weeks_to_deliver: 4) }
    7.times { FactoryBot.create(:part, supplier: @supplier2, minimum_on_hand: 20, weeks_to_deliver: 4) }
    3.times { FactoryBot.create(:part, supplier: nil, minimum_on_hand: 20, weeks_to_deliver: 4) }
    Part.all.each do |part|
      FactoryBot.create(:tech_part, part: part, technology: tech)
    end

    FactoryBot.create(:component_ct)
    5.times { FactoryBot.create(:component) }
    Component.all.each do |c|
      FactoryBot.create(:tech_comp, component: c, technology: tech)
    end

    5.times { FactoryBot.create(:material, supplier: @supplier1, minimum_on_hand: 20, weeks_to_deliver: 4) }
    2.times { FactoryBot.create(:material, supplier: @supplier2, minimum_on_hand: 20, weeks_to_deliver: 4) }
    2.times { FactoryBot.create(:material, supplier: nil, minimum_on_hand: 20, weeks_to_deliver: 4) }
    Material.all.each do |m|
      FactoryBot.create(:material_part, material: m, part: Part.find(Random.rand(Part.first.id..Part.last.id)))
      # every material needs an extrapolate_material_parts && an extrapolate_component_parts through the part.
      ExtrapolateComponentPart.where(component: Component.find(Random.rand(Component.first.id..Component.last.id)), part: m.extrapolate_material_parts.first.part).first_or_create
    end

    @user = FactoryBot.create(:admin)

    InventoriesController::CountCreate.new(@inventory, [], @user)

    Count.all.each do |c|
      c.loose_count = Random.rand(0..15)
      c.save
    end
  end

  after :all do
    clean_up!
  end

  context 'when visited by' do
    it 'anon users redirects to sign_in page' do
      visit order_inventories_path

      expect(page).to have_content 'You need to sign in first'
      expect(page).to have_content 'Sign in'
    end

    it 'builders redirects to home page' do
      sign_in FactoryBot.create(:user)

      visit order_inventories_path

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'leaders redirects to home page' do
      sign_in FactoryBot.create(:leader)

      visit order_inventories_path

      expect(page).to have_content 'You don\'t have permission'
      expect(page).to have_content 'Upcoming Builds'
    end

    it 'inventory users shows the page' do
      sign_in FactoryBot.create(:user, does_inventory: true)
      visit order_inventories_path

      expect(page).to have_content 'items need to be ordered:'
    end

    it 'users who receive inventory emails shows the page' do
      sign_in FactoryBot.create(:user, send_inventory_emails: true)
      visit order_inventories_path

      expect(page).to have_content 'items need to be ordered:'
    end

    it 'admins shows the page' do
      sign_in FactoryBot.create(:admin)
      visit order_inventories_path

      expect(page).to have_content 'items need to be ordered:'
    end
  end

  context 'shows items that need to be ordered' do
    before :each do
      sign_in FactoryBot.create(:admin)
      visit order_inventories_path
    end

    it 'in a single table' do
      expect(page).to have_css('table#order_item_tbl')
      expect(page).to have_css('table#order_item_tbl tbody tr', count: (Part.orderable.size + Material.all.size))
    end

    it 'by supplier' do
      click_link 'By Supplier'

      expect(page).to have_css('table.datatable-order-supplier', count: Supplier.all.size + 1)
      expect(page).to have_content @supplier1.name
      expect(page).to have_content @supplier2.name
      expect(page).to have_content 'Items without a supplier:'
    end
  end

  # context 'has js that' do
  #   before :each do
  #     sign_in FactoryBot.create(:admin)

  #     low_counts = @inventory.counts.select(&:reorder?)
  #     total_cost = low_counts.map { |c| c.item.reorder_total_cost }.sum
  #     @cost_check = total_cost.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse

  #     visit order_inventories_path
  #   end

    # context 'displays a price based upon checkboxes' do
      # it 'on the item view' do
        # UX check passes, CircleCI passes, local fails
        # expect(find(:css, '#item_ttl').native.text).to eq @cost_check

        # click_link 'uncheck_all'
        # expect(find(:css, '#item_ttl').native.text).to eq '0.00'

        # click_link 'check_all'
        # expect(find(:css, '#item_ttl').native.text).to eq @cost_check
      # end

      # it 'on the supplier view' do
        # UX check passes, CircleCI passes, local fails
        # click_link 'supplier_btn'

        # expect(find(:css, '#supplier_ttl').native.text).to eq @cost_check

        # click_link 'uncheck_all'
        # expect(find(:css, '#supplier_ttl').native.text).to eq '0.00'

        # click_link 'check_all'
        # expect(find(:css, '#supplier_ttl').native.text).to eq @cost_check
      # end
    # end

    # it 'checks the apropriate box when the order quantity is changed' do
      # UX check passes, CircleCI passes, local fails
      # count_str = find('#order_item_tbl tbody').first('tr')[:id]
      # count = Count.find(count_str)

      # checkbox = find('#checkbox_item_' + count.id.to_s)

      # expect(checkbox).to be_checked

      # click_link 'uncheck_all'

      # expect(checkbox).to_not be_checked

      # field_id = 'item_min_order_' + count.id.to_s
      # fill_in(field_id, with: count.item.min_order + 200)
      # find('#title').click

      # expect(checkbox).to be_checked
    # end

    # it 'keeps the twin checkboxes in sync' do
      # UX check passes, CircleCI passes, local fails
      # count = Count.first

      # twin_a = find('#checkbox_item_' + count.id.to_s)
      # twin_b = find('#checkbox_supplier_' + count.id.to_s, visible: false)

      # expect(twin_a).to be_checked
      # expect(twin_b).to be_checked

      # click_link 'uncheck_all'

      # expect(twin_a).to_not be_checked
      # expect(twin_b).to_not be_checked

      # twin_a.set(true)

      # expect(twin_a).to be_checked
      # expect(twin_b).to be_checked

      # click_link 'supplier_btn'

      # twin_a = find('#checkbox_item_' + count.id.to_s, visible: false)
      # twin_b = find('#checkbox_supplier_' + count.id.to_s)

      # twin_b.set(false)

      # expect(twin_a).to_not be_checked
      # expect(twin_b).to_not be_checked
    # end
  # end
end
