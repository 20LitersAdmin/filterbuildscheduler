class RemoveSupplierNameFromPartAndMaterial < ActiveRecord::Migration[5.1]
  def change

    remove_column :parts, :supplier_name
    
  end
end
