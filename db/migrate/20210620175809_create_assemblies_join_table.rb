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
      asbly = Assembly.find_or_initialize_by(
        combination_id: e.component_id,
        combination_type: 'Component',
        item_id: e.part_id,
        item_type: 'Part'
      )

      next unless asbly.new_record?

      asbly.save
      # e.really_destroy if asbly.save
    end

    # migrate extrapolate_technology_components into assemblies
    ExtrapolateTechnologyComponent.all.each do |e|
      asbly = Assembly.find_or_initialize_by(
        combination_type: 'Technology',
        combination_id: e.technology_id,
        item_type: 'Component',
        item_id: e.component_id
      )

      next unless asbly.new_record?

      asbly.quantity = e.components_per_technology
      asbly.save
      # e.really_destroy if asbly.save
    end

    # create assemblies for Parts in Technologies
    Technology.list_worthy.each do |t|
      req_comps = ExtrapolateTechnologyComponent.where(technology_id: t.id, required: true).pluck(:component_id)
      used_part_ids = ExtrapolateComponentPart.where(component_id: req_comps).pluck(:part_id)

      ExtrapolateTechnologyPart.where(technology_id: t.id).where.not(part_id: used_part_ids).each do |etp|
        asbly = Assembly.find_or_initialize_by(
          combination_type: 'Technology',
          combination_id: etp.technology_id,
          item_type: 'Part',
          item_id: etp.part_id
        )

        next unless asbly.new_record?

        asbly.quantity = etp.parts_per_technology
        asbly.save
        # etp.really_destroy if asbly.save
      end
    end

    # and simplify the join table beetween Materials and Parts
    create_table :materials_parts, id: false do |t|
      t.belongs_to :part
      t.belongs_to :material
      t.decimal :quantity, precision: 8, scale: 4, default: 1, null: false
    end

    add_index :materials_parts, [:part_id, :material_id]

    ExtrapolateMaterialPart.all.each do |e|
      mp = MaterialsPart.find_or_initialize_by(
        part_id: e.part_id,
        material_id: e.material_id
      )

      next unless mp.new_record?

      mp.quantity = e.parts_per_material
      mp.save
      # e.really_destroy if mp.save
    end

    # destroy ExtrapolateComponentPart table only if all records are transferred
    # drop_table 'extrapolate_component_parts' if ExtrapolateComponentPart.all.size.zero?

    # destroy ExtrapolateTechnologyComponent table only if all records are transferred
    # drop_table 'extrapolate_technology_components' if ExtrapolateTechnologyComponent.all.size.zero?

    # destroy ExtrapolateMaterialPart table only if all records are transferred
    # drop_table 'extrapolate_material_parts' if ExtrapolateMaterialPart.all.size.zero?
  end
end
