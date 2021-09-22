# frozen_string_literal: true

class DropExtrapTables < ActiveRecord::Migration[6.1]
  # TODO: don't run this migration before running InventoryMigrationJob

  def change
    drop_table 'extrapolate_component_parts'
    drop_table 'extrapolate_technology_components'
    drop_table 'extrapolate_technology_parts'
    drop_table 'extrapolate_technology_materials'
    drop_table 'extrapolate_material_parts'
  end
end
