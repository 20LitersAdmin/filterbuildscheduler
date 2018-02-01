class AddSuppliers < ActiveRecord::Migration[5.1]
  def change

    create_table :suppliers, do |t|
      t.string :name
      t.string :email
      t.string :address1
      t.string :address2
      t.string :city
      t.string :state
      t.string :zip
      t.string :province
      t.string :country
      t.string :phone
      t.string :url
      t.string :POC_name
      t.string :POC_email
      t.string :POC_phone
      t.string :POC_address
      t.text :comments
      t.datetime :deleted_at
      t.index ["name"], name: "index_suppliers_on_name"
    end

    create_table :supplier_parts, do |t|
      t.references :supplier
      t.references :part
      t.text :comments
      t.datetime :deleted_at
      t.index ["supplier_id", "part_id"], name: "index_supplier_parts_on_supplier_id_and_part_id"
      t.index ["part_id", "supplier_id"], name: "index_supplier_parts_on_part_id_and_supplier_id"
    end

    create_table :supplier_materials, do |t|
      t.references :supplier
      t.references :material
      t.text :comments
      t.datetime :deleted_at
      t.index ["supplier_id", "material_id"], name: "index_supplier_materials_on_supplier_id_and_material_id"
      t.index ["material_id", "supplier_id"], name: "index_supplier_materials_on_material_id_and_supplier_id"
    end

  end
end
