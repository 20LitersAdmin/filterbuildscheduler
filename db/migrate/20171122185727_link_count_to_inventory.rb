class LinkCountToInventory < ActiveRecord::Migration[5.1]
  def change

    change_table :counts do |t|
      t.references :inventory
    end
  end
end
