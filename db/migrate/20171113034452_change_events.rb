class ChangeEvents < ActiveRecord::Migration[5.1]
  def change
    rename_column :events, :item_results, :technologies_built
    add_column :events, :boxes_packed, :integer
  end
end
