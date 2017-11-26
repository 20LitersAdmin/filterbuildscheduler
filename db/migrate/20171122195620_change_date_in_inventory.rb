class ChangeDateInInventory < ActiveRecord::Migration[5.1]
  def change
    remove_column :inventories, :date

    add_column :inventories, :date, :date, null: false, default: Date.today
  end
end
