class AddSuppliers < ActiveRecord::Migration[5.1]
  def change

    create_table :suppliers do |t|
      t.string :name, null: false
      t.string :url
      t.string :email
      t.string :address1
      t.string :address2
      t.string :city
      t.string :state
      t.string :zip
      t.string :province
      t.string :country
      t.string :phone
      t.string :POC_name
      t.string :POC_email
      t.string :POC_phone
      t.string :POC_address
      t.text :comments
      t.datetime :deleted_at
      t.index ["name"], name: "index_suppliers_on_name"
    end

    create_table :supplier_parts do |t|
      t.references :supplier, null: false
      t.references :part, null: false
      t.string :order_url
      t.integer :min_order, default: 1, null: false
      t.string :sku
      t.float :weeks_to_deliver, default: 1, null: false
      t.integer :minimum_on_hand, default: 1, null: false
      t.integer :quantity_per_box, default: 1, null: false
      t.monetize :price, amount: { null: false, default: 0 }
      t.monetize :shipping, amount: { null: false, default: 0 }
      t.monetize :wire_transfer, amount: { null: false, default: 0 }
      t.monetize :additional_cost, amount: { null: false, default: 0 }
      t.text :comments
      t.datetime :deleted_at
      t.index ["supplier_id", "part_id"], name: "index_supplier_parts_on_supplier_id_and_part_id"
      t.index ["part_id", "supplier_id"], name: "index_supplier_parts_on_part_id_and_supplier_id"
    end

    create_table :supplier_materials do |t|
      t.references :supplier, null: false
      t.references :material, null: false
      t.string :order_url
      t.integer :min_order, default: 1, null: false
      t.string :sku
      t.float :weeks_to_deliver, default: 1, null: false
      t.integer :minimum_on_hand, default: 1, null: false
      t.integer :quantity_per_box, default: 1, null: false
      t.monetize :price, amount: { null: false, default: 0 }
      t.monetize :shipping, amount: { null: false, default: 0 }
      t.monetize :wire_transfer, amount: { null: false, default: 0 }
      t.monetize :additional_cost, amount: { null: false, default: 0 }
      t.text :comments
      t.datetime :deleted_at
      t.index ["supplier_id", "material_id"], name: "index_supplier_materials_on_supplier_id_and_material_id"
      t.index ["material_id", "supplier_id"], name: "index_supplier_materials_on_material_id_and_supplier_id"
    end

  end
end
