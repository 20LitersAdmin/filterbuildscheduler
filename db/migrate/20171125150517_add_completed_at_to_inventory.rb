class AddCompletedAtToInventory < ActiveRecord::Migration[5.1]
  def change
    add_column :inventories, :completed_at, :datetime
    change_column_default :inventories, :date, nil

    add_column :counts, :extrapolated_count, :integer, default: 0, null: false
  end
end
