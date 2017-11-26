class DropInventoriesTechnologiesJoinTbl < ActiveRecord::Migration[5.1]
  def change
    drop_table :inventories_technologies
  end
end
