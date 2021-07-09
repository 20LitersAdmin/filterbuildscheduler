# frozen_string_literal: true

class AddCountsToItemTables < ActiveRecord::Migration[6.1]
  def change
    add_column :materials,    :loose_count,          :integer, default: 0
    add_column :materials,    :box_count,            :integer, default: 0
    add_column :materials,    :available_count,      :integer, default: 0
    add_column :materials,    :history,              :jsonb, null: false, default: {}

    add_column :parts,        :loose_count,          :integer, default: 0
    add_column :parts,        :box_count,            :integer, default: 0
    add_column :parts,        :available_count,      :integer, default: 0
    add_column :parts,        :history,              :jsonb, null: false, default: {}

    add_column :components,   :loose_count,          :integer, default: 0
    add_column :components,   :box_count,            :integer, default: 0
    add_column :components,   :available_count,      :integer, default: 0
    add_column :components,   :history,              :jsonb, null: false, default: {}
    # RubyMoney columns
    add_monetize :components, :price

    add_column :technologies, :loose_count,          :integer, default: 0
    add_column :technologies, :box_count,            :integer, default: 0
    add_column :technologies, :available_count,      :integer, default: 0
    add_column :technologies, :history,              :jsonb, null: false, default: {}
    add_column :technologies, :quantities,           :jsonb, null: false, default: {}
    # RubyMoney columns
    add_monetize :technologies, :price

    ActiveRecord::Base.logger.level = 1

    puts 'add counts from latest inventory'

    Inventory.latest.counts.each do |c|
      c.item.update_columns(
        loose_count: c.loose_count,
        box_count: c.unopened_boxes_count,
        available_count: c.loose_count + (c.unopened_boxes_count * c.item.quantity_per_box)
      )
      c.destroy
    end

    puts 'add history to every item'
    Inventory.order(date: :desc, created_at: :desc).each do |i|
      i.counts.each do |c|
        item = c.item
        item.history[c.inventory_id] = c.history_json
        item.save!
        c.destroy
      end
    end

    puts 'transfer counts from Components.where(completed_tech: true) to Technology'
    Component.where(completed_tech: true).each do |comp|
      tech = ExtrapolateTechnologyComponent.where(component_id: comp.id).first.technology

      tech.update_columns(
        loose_count: comp.loose_count,
        box_count: comp.box_count,
        available_count: comp.available_count,
        history: comp.history
      )

      comp.update_columns(deleted_at: Time.now)
    end

    puts 'Data has been migrated, delete any remaining counts'
    Count.all.delete_all unless Count.all.size.zero?
    ActiveRecord::Base.connection.reset_pk_sequence!('counts')

    puts 'Count: switch from booleans to polymorphic'
    # count.item_type && count.item_id
    add_reference :counts, :item, polymorphic: true, index: true
    remove_column :counts, :component_id
    remove_column :counts, :material_id
    remove_column :counts, :part_id

    ActiveRecord::Base.logger.level = 1
  end
end
