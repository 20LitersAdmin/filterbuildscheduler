class LotsONewVals < ActiveRecord::Migration[5.1]
  def change

    #add_column :counts, :partial, :boolean, default: false

    add_column :users, :email_opt_out, :boolean, default: false

    add_monetize :parts, :shipping_cost
    add_monetize :parts, :wire_transfer_cost
  end
end
