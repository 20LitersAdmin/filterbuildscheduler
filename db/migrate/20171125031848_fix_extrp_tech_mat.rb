class FixExtrpTechMat < ActiveRecord::Migration[5.1]
  def change

    drop_table :extrapolate_technology_materials

    create_join_table :materials, :technologies do |t|
      t.index :material_id
      t.index :technology_id
    end
  end
end
