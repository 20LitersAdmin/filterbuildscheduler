# frozen_string_literal: true

class ChangePartQuanitityFromMaterialToInteger < ActiveRecord::Migration[6.1]
  def up
    Part.where(quantity_from_material: nil).update_all(quantity_from_material: 0)

    change_column :parts, :quantity_from_material, :integer, default: 0, null: false
  end

  def down
    change_column :parts, :quantity_from_material, :float
  end
end
