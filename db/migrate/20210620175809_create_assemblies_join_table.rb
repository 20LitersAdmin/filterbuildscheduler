# frozen_string_literal: true

class CreateAssembliesJoinTable < ActiveRecord::Migration[6.1]
  def change
    # create the polymorphic join table used to link Technologies, Components and Parts
    # combination: the "parent" nodel
    # item: the "child" node
    # quantity: number of items per combination
    # priority: makes Assemblies orderable via item_type: { 'Component' => 0, 'Part' => 1 }
    create_table :assemblies do |t|
      t.bigint   :combination_id,   null: false
      t.string   :combination_type, null: false
      t.bigint   :item_id,          null: false
      t.string   :item_type,        null: false
      t.integer  :quantity,         null: false, default: 1
      t.monetize :price
      t.integer  :depth
    end

    add_index :assemblies, [:item_id, :item_type]
    add_index :assemblies, [:combination_id, :combination_type]

    # Part belongs_to Material
    add_reference :parts, :material
    rename_column :parts, :made_from_materials, :made_from_material
    add_column :parts, :quantity_from_material, :float, precision: 8, scale: 4, default: nil
  end
end
