class AddIDsToExtrapTbls < ActiveRecord::Migration[5.1]
  def change
    add_column :extrapolate_component_parts,       :id, :primary_key
    add_column :extrapolate_technology_components, :id, :primary_key
    add_column :extrapolate_material_parts,        :id, :primary_key
    add_column :extrapolate_technology_parts,      :id, :primary_key
  end
end
