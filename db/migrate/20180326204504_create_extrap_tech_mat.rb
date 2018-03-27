class CreateExtrapTechMat < ActiveRecord::Migration[5.1]
  def change
    # drop_table :extrapolate_technology_materials

    create_table :extrapolate_technology_materials do |t|
      t.references :technology
      t.references :material
      t.float :materials_per_technology, default: 1, null: false
      t.boolean :required, default: false, null: false
      t.index [:material_id, :technology_id], name: "index_materials_technologies_on_material"
      t.index [:technology_id, :material_id], name: "index_materials_technologies_on_technology"
    end

    drop_join_table :materials, :technologies
  end
end
