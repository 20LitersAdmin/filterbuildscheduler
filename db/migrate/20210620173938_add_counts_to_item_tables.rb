# frozen_string_literal: true

class AddCountsToItemTables < ActiveRecord::Migration[6.1]
  def change
    add_column :materials,    :uid,                  :string
    add_column :materials,    :loose_count,          :integer, default: 0
    add_column :materials,    :box_count,            :integer, default: 0
    add_column :materials,    :available_count,      :integer, default: 0
    add_column :materials,    :history,              :jsonb, null: false, default: {}
    add_column :materials,    :quantities,           :jsonb, null: false, default: {}

    add_column :parts,        :uid,                  :string
    add_column :parts,        :loose_count,          :integer, default: 0
    add_column :parts,        :box_count,            :integer, default: 0
    add_column :parts,        :available_count,      :integer, default: 0
    add_column :parts,        :history,              :jsonb, null: false, default: {}
    add_column :parts,        :quantities,           :jsonb, null: false, default: {}

    add_column :components,   :uid,                  :string
    add_column :components,   :loose_count,          :integer, default: 0
    add_column :components,   :box_count,            :integer, default: 0
    add_column :components,   :available_count,      :integer, default: 0
    add_column :components,   :history,              :jsonb, null: false, default: {}
    add_column :components,    :quantities,           :jsonb, null: false, default: {}

    # RubyMoney columns
    add_monetize :components, :price

    add_column :technologies, :uid,                  :string
    add_column :technologies, :only_loose,           :boolean, default: false
    add_column :technologies, :loose_count,          :integer, default: 0
    add_column :technologies, :box_count,            :integer, default: 0
    add_column :technologies, :available_count,      :integer, default: 0
    add_column :technologies, :history,              :jsonb, null: false, default: {}
    add_column :technologies, :quantities,           :jsonb, null: false, default: {}
    add_column :technologies, :quantity_per_box,     :integer, default: 1
    # RubyMoney columns
    add_monetize :technologies, :price

    # count.item_type && count.item_id
    add_reference :counts, :item, polymorphic: true, index: true
  end
end
