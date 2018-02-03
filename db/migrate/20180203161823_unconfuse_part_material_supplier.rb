class UnconfusePartMaterialSupplier < ActiveRecord::Migration[5.1]
  def change

    change_table :parts do |t|
      t.rename :supplier, :supplier_name
    end

    change_table :materials do |t|
      t.rename :supplier, :supplier_name
    end
  end
end
