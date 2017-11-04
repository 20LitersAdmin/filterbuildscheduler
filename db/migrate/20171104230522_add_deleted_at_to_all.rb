class AddDeletedAtToAll < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :is_archived
    add_column :users, :deleted_at, :datetime
    add_index :users, :deleted_at
    add_column :events, :deleted_at, :datetime
    add_index :events, :deleted_at
    add_column :locations, :deleted_at, :datetime
    add_index :locations, :deleted_at
    add_column :technologies, :deleted_at, :datetime
    add_index :technologies, :deleted_at
  end
end
