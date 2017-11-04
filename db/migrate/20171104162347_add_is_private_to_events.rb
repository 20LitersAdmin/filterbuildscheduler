class AddIsPrivateToEvents < ActiveRecord::Migration[5.1]
  def change
    add_column :events, :is_private, :boolean, null: false, default: false
  end
end
