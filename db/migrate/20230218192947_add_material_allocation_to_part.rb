class AddMaterialAllocationToPart < ActiveRecord::Migration[6.1]
  def change
    add_column :parts, :allocations, :jsonb, null: false, default: {}
    add_column :components, :allocations, :jsonb, null: false, default: {}
    add_column :materials, :allocations, :jsonb, null: false, default: {}
  end
end
