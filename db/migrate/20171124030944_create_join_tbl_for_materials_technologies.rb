class CreateJoinTblForMaterialsTechnologies < ActiveRecord::Migration[5.1]
  def change
    create_join_table :materials, :technologies do |t|
      t.index [:material_id, :technology_id], name: "index_materials_technologies_on_material"
      t.index [:technology_id, :material_id], name: "index_materials_technologies_on_technology"
    end
  end
end
