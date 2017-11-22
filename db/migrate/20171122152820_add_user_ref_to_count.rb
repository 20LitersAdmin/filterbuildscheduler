class AddUserRefToCount < ActiveRecord::Migration[5.1]
  def change

    change_table :counts do |t|
      t.references :user
    end

    change_table :inventories do |t|
      t.remove :reported
      t.boolean :shipping, default: false, null: false
    end

    drop_table :inventories_users
  end
end
