# frozen_string_literal: true

class CreateAssembliesJoinTable < ActiveRecord::Migration[6.1]
  def change
    create_table :assemblies, id: false do |t|
      t.bigint  :combination_id,   null: false
      t.string  :combination_type, null: false
      t.bigint  :item_id,          null: false
      t.string  :item_type,        null: false
      t.integer :quantity,         null: false, default: 1
    end

    add_index :assemblies, [:item_id, :item_type]
    add_index :assemblies, [:combination_id, :combination_type]

    # migrate extrapolate_component_parts into assemblies
    ExtrapolateComponentPart.all.each do |e|
      next if Assembly.where(combination_id: e.component_id, item_id: e.part_id).any?

      asbly = Assembly.new(
        combination_id: e.component_id,
        combination_type: 'Component',
        item_id: e.part_id,
        item_type: 'Part',
        quantity: e.parts_per_component
      )
      asbly.save
      # e.really_destroy if asbly.save
    end

    # migrate extrapolate_technology_components into assemblies
    ExtrapolateTechnologyComponent.all.each do |e|
      next if Assembly.where(combination_id: e.technology_id, item_id: e.component_id).any?

      asbly = Assembly.new(
        combination_id: e.technology_id,
        combination_type: 'Technology',
        item_id: e.component_id,
        item_type: 'Component',
        quantity: e.components_per_technology
      )
      asbly.save
      # e.really_destroy if asbly.save
    end

    # and simplify the join table beetween Materials and Parts
    create_table :materials_parts, id: false do |t|
      t.belongs_to :part
      t.belongs_to :material
      t.decimal :quantity, precision: 8, scale: 4, default: 1, null: false
    end

    add_index :materials_parts, [:part_id, :material_id]

    ExtrapolateMaterialPart.all.each do |e|
      mp = MaterialsPart.new(
        part_id: e.part_id,
        material_id: e.material_id,
        quantity: e.parts_per_material
      )
      mp.save
      # e.really_destroy if mp.save
    end

    # destroy ExtrapolateMaterialPart
  end
end
