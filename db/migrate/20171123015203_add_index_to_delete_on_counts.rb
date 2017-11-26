class AddIndexToDeleteOnCounts < ActiveRecord::Migration[5.1]
  def change
    add_index :counts, :deleted_at
  end
end
