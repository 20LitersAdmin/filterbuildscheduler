class RemoveGCalFromEvents < ActiveRecord::Migration[5.1]
  def change
    remove_column :events, :gcal_id
  end
end
