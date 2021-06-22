# frozen_string_literal: true

class AddCountsToItemTables < ActiveRecord::Migration[6.1]
  def change
    # add_column :materials,    :loose_count,          :integer, default: 0
    # add_column :materials,    :box_count,            :integer, default: 0
    # add_column :materials,    :loose_count_previous, :integer, default: 0
    # add_column :materials,    :box_count_previous,   :integer, default: 0
    # add_column :materials,    :count_date,           :datetime, index: true
    # add_column :materials,    :count_date_previous,  :datetime, index: true

    # add_column :parts,        :loose_count,          :integer, default: 0
    # add_column :parts,        :box_count,            :integer, default: 0
    # add_column :parts,        :loose_count_previous, :integer, default: 0
    # add_column :parts,        :box_count_previous,   :integer, default: 0
    # add_column :parts,        :count_date,           :datetime, index: true
    # add_column :parts,        :count_date_previous,  :datetime, index: true

    # add_column :components,   :loose_count,          :integer, default: 0
    # add_column :components,   :box_count,            :integer, default: 0
    # add_column :components,   :loose_count_previous, :integer, default: 0
    # add_column :components,   :box_count_previous,   :integer, default: 0
    # add_column :components,   :count_date,           :datetime, index: true
    # add_column :components,   :count_date_previous,  :datetime, index: true

    # add_column :technologies, :loose_count,          :integer, default: 0
    # add_column :technologies, :box_count,            :integer, default: 0
    # add_column :technologies, :loose_count_previous, :integer, default: 0
    # add_column :technologies, :box_count_previous,   :integer, default: 0
    # add_column :technologies, :count_date,           :datetime, index: true
    # add_column :technologies, :count_date_previous,  :datetime, index: true
    # # Allows for filtering out of technologies that shouldn't be inventoried
    # add_column :technologies, :inventoryable,        :boolean, default: true, index: true

    # # add counts from latest inventory
    # inv = Inventory.latest
    # latest_date = inv.date
    # inv.counts.each do |c|
    #   c.item.update_columns(
    #     loose_count: c.loose_count,
    #     box_count: c.unopened_boxes_count,
    #     count_date: latest_date
    #   )
    # end

    # # add counts from previous inventory
    # prev_inv = Inventory.former.first
    # prev_date = prev_inv.date
    # prev_inv.counts.each do |c|
    #   c.item.update_columns(
    #     loose_count_previous: c.loose_count,
    #     box_count_previous: c.unopened_boxes_count,
    #     count_date_previous: prev_date
    #   )
    # end

    # # transfer counts from Components.where(completed_tech: true) to Technology
    # Component.where(completed_tech: true).each do |comp|
    #   tech = comp.technology
    #   tech.update_columns(
    #     loose_count: comp.loose_count,
    #     box_count: comp.box_count,
    #     loose_count_previous: comp.loose_count_previous,
    #     box_count_previous: comp.box_count_previous,
    #     count_date: comp.count_date,
    #     count_date_previous: comp.count_date_previous
    #   )
    # end

    # # Count: switch from booleans to polymorphic
    # #   count.item_type && count.item_id
    # add_reference :counts, :item, polymorphic: true, index: true
  end
end
