class RemoveSupplierJoinTables < ActiveRecord::Migration[5.1]
  def change

    drop_table :parts_suppliers
    drop_table :materials_suppliers

    change_table :parts do |t|
      t.references :supplier
    end

    change_table :materials do |t|
      t.references :supplier
    end
    
  end
end
