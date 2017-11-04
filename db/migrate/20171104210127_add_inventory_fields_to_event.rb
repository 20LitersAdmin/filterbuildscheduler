class AddInventoryFieldsToEvent < ActiveRecord::Migration[5.1]
  def change
    add_column :events, :item_goal, :integer
    add_column :events, :item_results, :integer
  end
end
