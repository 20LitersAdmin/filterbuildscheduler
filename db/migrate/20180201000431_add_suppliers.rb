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

    create_join_table :suppliers, :parts, table_name: :supplier_parts do |t|
      t.index [:supplier_id, :part_id], unique: true
      t.index [:part_id, :supplier_id], unique: true
    end

    create_join_table :suppliers, :materials, table_name: :supplier_materials do |t|
      t.index [:supplier_id, :material_id], unique: true
      t.index [:material_id, :supplier_id], unique: true
    end

  end
end
