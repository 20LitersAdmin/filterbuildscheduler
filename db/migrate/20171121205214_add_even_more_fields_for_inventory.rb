class AddEvenMoreFieldsForInventory < ActiveRecord::Migration[5.1]
  def change
    add_column :parts, :additional_cost_cents, :float, default: 0
    add_column :parts, :additional_cost_currency, :string, default: "USD", null: false
    add_column :materials, :additional_cost_cents, :float, default: 0
    add_column :materials, :additional_cost_currency, :string, default: "USD", null: false

    # add_foreign_key "components", "counts"
    # add_foreign_key "counts", "components"
    # add_foreign_key "components", "parts"
    # add_foreign_key "parts", "components"
    # add_foreign_key "components", "technologies"
    # add_foreign_key "technologies", "components"
    # add_foreign_key "counts", "materials"
    # add_foreign_key "materials", "counts"
    # add_foreign_key "counts", "parts"
    # add_foreign_key "parts", "counts"
    # add_foreign_key "inventories", "technologies"
    # add_foreign_key "technologies", "inventories"
    # add_foreign_key "inventories", "users"
    # add_foreign_key "users", "inventories"
    # add_foreign_key "materials", "parts"
    # add_foreign_key "parts", "materials"
    # add_foreign_key "parts", "technologies"
    # add_foreign_key "technologies", "parts"
    # add_foreign_key "technologies", "users"
    # add_foreign_key "users", "technologies"
  end
end
