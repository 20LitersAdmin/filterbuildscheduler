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

    # simplify the join table beetween Materials and Parts
    # to get `quantity`, call `part.quantity_from_material`
    create_table :materials_parts do |t|
      t.belongs_to :material
      t.belongs_to :part
      t.decimal :quantity, precision: 8, scale: 4, default: 1, null: false
    end

    add_index :materials_parts, [:part_id, :material_id], unique: true
  end
end
