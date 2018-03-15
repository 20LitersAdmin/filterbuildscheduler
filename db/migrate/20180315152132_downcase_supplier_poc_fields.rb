class DowncaseSupplierPocFields < ActiveRecord::Migration[5.1]
  def change

    rename_column :suppliers, :POC_name, :poc_name
    rename_column :suppliers, :POC_email, :poc_email
    rename_column :suppliers, :POC_phone, :poc_phone
    rename_column :suppliers, :POC_address, :poc_address
  end
end
