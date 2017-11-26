class AddForeignKeysForInventory < ActiveRecord::Migration[5.1]
  def change
    add_foreign_key :extrapolate_component_parts,       :components
    add_foreign_key :extrapolate_component_parts,       :parts
    add_foreign_key :extrapolate_technology_components, :technologies
    add_foreign_key :extrapolate_technology_components, :components
    add_foreign_key :extrapolate_material_parts,        :materials
    add_foreign_key :extrapolate_material_parts,        :parts
    add_foreign_key :extrapolate_technology_materials,  :technologies
    add_foreign_key :extrapolate_technology_materials,  :materials
    add_foreign_key :extrapolate_technology_parts,      :technologies
    add_foreign_key :extrapolate_technology_parts,      :parts

  end
end
