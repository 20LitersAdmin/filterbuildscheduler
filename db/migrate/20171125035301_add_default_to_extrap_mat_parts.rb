class AddDefaultToExtrapMatParts < ActiveRecord::Migration[5.1]
  def change
    change_column_default :extrapolate_material_parts, :parts_per_material, 1
  end
end
