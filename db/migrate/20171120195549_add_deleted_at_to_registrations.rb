class AddDeletedAtToRegistrations < ActiveRecord::Migration[5.1]
  def change
    add_column :registrations, :deleted_at, :datetime
  end
end
