class AddGcalIdToEvents < ActiveRecord::Migration[5.1]
  def change
    add_column :events, :gcal_id, :string
  end
end
