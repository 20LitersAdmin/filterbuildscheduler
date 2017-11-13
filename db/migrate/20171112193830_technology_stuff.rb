class TechnologyStuff < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :does_inventory , :boolean

    create_table :materials do |t|
      t.string :name, null: false
      t.string :supplier
      t.string :order_url
      t.monetize :price, amount: { null: true, default: nil }
      t.integer :min_order
      t.string :order_id
      t.float :weeks_to_deliver
      t.timestamps
    end

    create_table :parts do |t|
      t.string :name, null: false
      t.string :supplier
      t.string :order_url
      t.monetize :price, amount: { null: true, default: nil }
      t.integer :min_order
      t.string :order_id
      t.string :common_id
      t.float :weeks_to_deliver
      t.integer :sample_size
      t.float :sample_weight
      t.boolean :made_from_materials, default: false
      t.timestamps
    end

    create_table :components do |t|
      t.string :name, null: false
      t.integer :sample_size
      t.float :sample_weight
      t.string :common_id
      t.boolean :completed_tech
      t.boolean :completed_tech_boxed
      t.timestamps
    end

    create_join_table :materials, :parts do |t|
      t.index [:material_id, :part_id]
      t.index [:part_id, :material_id]
      t.integer :parts_per_material, null: false
    end

    create_join_table :components, :parts do |t|
      t.index [:component_id, :part_id]
      t.index [:part_id, :component_id]
      t.integer :parts_per_component, null: false, default: 1
    end

    create_table :components_parts_technologies, id: false do |t|
      t.references :components, index: true, foreign_key: true
      t.references :parts, index: true, foreign_key: true
      t.references :technologies, index: true, foreign_key: true, null: false
      t.integer :items_per_technology, null: false, default: 1
    end

  end
end
