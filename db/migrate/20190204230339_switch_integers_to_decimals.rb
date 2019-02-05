# frozen_string_literal: true

class SwitchIntegersToDecimals < ActiveRecord::Migration[5.2]
  def change
    change_column :extrapolate_component_parts,       :parts_per_component,       :decimal, precision: 8, scale: 4
    change_column :extrapolate_material_parts,        :parts_per_material,        :decimal, precision: 8, scale: 4
    change_column :extrapolate_technology_components, :components_per_technology, :decimal, precision: 8, scale: 4
    change_column :extrapolate_technology_materials,  :materials_per_technology,  :decimal, precision: 8, scale: 4
    change_column :extrapolate_technology_parts,      :parts_per_technology,      :decimal, precision: 8, scale: 4
  end
end
