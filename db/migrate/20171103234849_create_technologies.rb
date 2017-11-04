class CreateTechnologies < ActiveRecord::Migration[5.1]
  def change
    create_table :technologies do |t|
      t.string :name, null: false
      t.string :description
      t.integer :ideal_build_length
      t.integer :ideal_group_size
      t.integer :ideal_leaders
      t.boolean :family_friendly # Appropriate for builders under 12
      t.float :unit_rate # Estimated filters per person per hour
      t.timestamps
    end
  end
end
