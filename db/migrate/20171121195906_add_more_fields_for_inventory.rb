class AddMoreFieldsForInventory < ActiveRecord::Migration[5.1]
  def change
    add_column :parts, :quantity_per_box, :integer, default: 1
    add_column :materials, :quantity_per_box, :integer, default: 1
    add_column :components, :quantity_per_box, :integer, default: 1

    add_column :users, :send_inventory_emails, :boolean, default: false

    remove_column :components, :completed_tech_boxed, :boolean
    change_column_default :components, :completed_tech, false
    add_column :components, :tare_weight, :float, default: 0

    add_index :components, :deleted_at
    add_index :counts, :deleted_at
    add_index :inventories, :deleted_at
    add_index :materials, :deleted_at
    add_index :parts, :deleted_at
    add_index :registrations, :deleted_at
  end
end
