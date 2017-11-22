class AddManualToInventory < ActiveRecord::Migration[5.1]
  def change
    add_column :inventories, :manual, :boolean, default: false, null: false
  end
end
