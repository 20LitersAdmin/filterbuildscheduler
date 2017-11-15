class InventoryStuff < ActiveRecord::Migration[5.1]
  def change
    create_table :inventories do |t|
      t.datetime :date, null: false
      t.boolean :reported, default: false, null: false
      t.boolean :receiving, default: false, null: false
      t.datetime :deleted_at
      t.timestamps
    end

    create_table :counts do |t|
      t.references :components, index: true
      t.references :parts, index: true
      t.references :materials, index: true
      t.integer :loose_count, null: false, default: 0
      t.integer :unopened_boxes_count, null: false, default: 0
      t.datetime :deleted_at
      t.timestamps
    end

    create_join_table :inventories, :technologies do |t|
      t.index [:inventory_id, :technology_id], name: "index_inventories_technologies_on_inventory"
      t.index [:technology_id, :inventory_id], name: "index_inventories_technologies_on_technology"
    end

    create_join_table :inventories, :users do |t|
      t.index [:inventory_id, :user_id]
      t.index [:user_id, :inventory_id]
    end

    create_join_table :components, :counts do |t|
      t.index [:component_id, :count_id]
      t.index [:count_id, :component_id]
    end

    create_join_table :counts, :parts do |t|
      t.index [:count_id, :part_id]
      t.index [:part_id, :count_id]
    end

    create_join_table :counts, :materials do |t|
      t.index [:count_id, :material_id]
      t.index [:material_id, :count_id]
    end
  end
end
