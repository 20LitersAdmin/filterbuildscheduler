class AddUniqueIndexToRegistrations < ActiveRecord::Migration[5.1]
  def change
    add_index :registrations, [:user_id, :event_id], unique: true
  end
end
