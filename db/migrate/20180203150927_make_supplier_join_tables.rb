class MakeSupplierJoinTables < ActiveRecord::Migration[5.1]
  def change
    drop_table :supplier_materials
    drop_table :supplier_parts

    create_join_table :suppliers, :parts do |t|
      t.index [:supplier_id, :part_id], unique: true
      t.index [:part_id, :supplier_id], unique: true
    end

    create_join_table :suppliers, :materials do |t|
      t.index [:supplier_id, :material_id], unique: true
      t.index [:material_id, :supplier_id], unique: true
    end
    
  end
end
