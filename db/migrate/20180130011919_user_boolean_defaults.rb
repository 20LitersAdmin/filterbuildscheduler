class UserBooleanDefaults < ActiveRecord::Migration[5.1]
  def change

    change_column_default :users, :is_admin, false
    change_column_default :users, :is_leader, false
    change_column_default :users, :does_inventory, false
  end
end
