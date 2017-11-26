class DitchCountJoinTables < ActiveRecord::Migration[5.1]
  def change

    drop_table :counts
    drop_table :counts_materials
    drop_table :counts_parts
    drop_table :components_counts

    create_table :counts do |t|
      t.references :user
      t.references :inventory, null: false
      t.references :component
      t.references :part
      t.references :material
      t.integer :loose_count, default: 0, null: false
      t.integer :unopened_boxes_count, default: 0, null: false
      t.datetime :deleted_at
    end

  end
end
