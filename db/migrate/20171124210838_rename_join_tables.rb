class RenameJoinTables < ActiveRecord::Migration[5.1]
  def change

    remove_index :components_parts, column: [:component_id, :part_id]
    remove_index :components_parts, column: [:part_id, :component_id]
    remove_index :components_technologies, column: [:component_id, :technology_id]
    remove_index :components_technologies, column: [:technology_id, :component_id]
    remove_index :materials_parts, column: [:material_id, :part_id]
    remove_index :materials_parts, column: [:part_id, :material_id]
    remove_index :materials_technologies, column: [:material_id, :technology_id]
    remove_index :materials_technologies, column: [:technology_id, :material_id]
    remove_index :parts_technologies, column: [:part_id, :technology_id]
    remove_index :parts_technologies, column: [:technology_id, :part_id]

    rename_table :components_parts, :extrapolate_component_parts
    rename_table :components_technologies, :extrapolate_technology_components
    rename_table :materials_parts, :extrapolate_material_parts
    rename_table :materials_technologies, :extrapolate_technology_materials
    rename_table :parts_technologies, :extrapolate_technology_parts

    add_index :extrapolate_component_parts,         [:component_id, :part_id], unique: true, name: 'by_component_and_part'
    add_index :extrapolate_component_parts,         [:part_id, :component_id], unique: true, name: 'by_part_and_component'
    add_index :extrapolate_technology_components,   [:technology_id, :component_id], unique: true, name: 'by_technology_and_component'
    add_index :extrapolate_technology_components,   [:component_id, :technology_id], unique: true, name: 'by_component_and_technology'
    add_index :extrapolate_material_parts,          [:material_id, :part_id], unique: true, name: 'by_material_and_part'
    add_index :extrapolate_material_parts,          [:part_id, :material_id], unique: true, name: 'by_part_and_material'
    add_index :extrapolate_technology_materials,    [:technology_id, :material_id], unique: true, name: 'by_technology_and_material'
    add_index :extrapolate_technology_materials,    [:material_id, :technology_id], unique: true, name: 'by_material_and_technology'
    add_index :extrapolate_technology_parts,        [:technology_id, :part_id], unique: true, name: 'by_technology_and_part'
    add_index :extrapolate_technology_parts,        [:part_id, :technology_id], unique: true, name: 'by_part_and_technology'

  end
end
