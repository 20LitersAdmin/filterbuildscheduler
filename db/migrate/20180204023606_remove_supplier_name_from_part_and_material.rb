class RemoveSupplierNameFromPartAndMaterial < ActiveRecord::Migration[5.1]
  def change

    remove_column :parts, :supplier_name, :string
    remove_column :materials, :supplier_name, :string
    
    rename_column :parts, :order_id, :sku
    rename_column :materials, :order_id, :sku

    remove_column :parts, :common_id

    change_table :materials do |t|
      t.monetize :shipping_cost, default: 0
      t.monetize :wire_transfer_cost, default: 0
    end
  end
end
