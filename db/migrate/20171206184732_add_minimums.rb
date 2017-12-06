class AddMinimums < ActiveRecord::Migration[5.1]
  def change

    change_column_null :events, :item_goal, false
    change_column_null :events, :technologies_built, false
    change_column_null :events, :boxes_packed, false

    change_column_default :events, :item_goal, 0
    change_column_default :events, :technologies_built, 0
    change_column_default :events, :boxes_packed, 0

    add_column :parts, :reorder_when, :integer, null: false, default: 0
    add_column :materials, :reorder_when, :integer, null: false, default: 0
  end
end
