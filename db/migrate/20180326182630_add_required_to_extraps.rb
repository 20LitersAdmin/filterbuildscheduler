class AddRequiredToExtraps < ActiveRecord::Migration[5.1]
  def change

    add_column :extrapolate_technology_components, :required, :boolean, default: false
    add_column :extrapolate_technology_parts, :required, :boolean, default: false
  end
end
