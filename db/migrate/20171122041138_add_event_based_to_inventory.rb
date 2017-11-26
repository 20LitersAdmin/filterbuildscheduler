class AddEventBasedToInventory < ActiveRecord::Migration[5.1]
  def change
    change_table :inventories do |t|
      t.references :event
    end
  end
end
