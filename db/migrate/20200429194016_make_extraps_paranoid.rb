# frozen_string_literal: true

class MakeExtrapsParanoid < ActiveRecord::Migration[5.2]
  def change
    add_column :extrapolate_component_parts, :deleted_at, :datetime
    add_column :extrapolate_material_parts, :deleted_at, :datetime
    add_column :extrapolate_technology_components, :deleted_at, :datetime
    add_column :extrapolate_technology_materials, :deleted_at, :datetime
    add_column :extrapolate_technology_parts, :deleted_at, :datetime
  end
end
