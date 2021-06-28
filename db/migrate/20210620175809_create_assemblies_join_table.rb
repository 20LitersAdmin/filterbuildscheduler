# frozen_string_literal: true

class CreateAssembliesJoinTable < ActiveRecord::Migration[6.1]
  def change
    create_table :assemblies do |t|
      t.bigint  :combination_id,   null: false
      t.string  :combination_type, null: false
      t.bigint  :item_id,          null: false
      t.string  :item_type,        null: false
      t.integer :quantity,         null: false, default: 1
      t.integer :priority
    end

    add_index :assemblies, [:item_id, :item_type]
    add_index :assemblies, [:combination_id, :combination_type]

    # create assemblies for Parts in Technologies
    # THIS IS DONE FIRST because it relies upon existing join table records
    # If it's run later, those records are already deleted and duplicates are created around the tree
    etp_start_count = ExtrapolateTechnologyPart.all.size
    etp_delete_counter = 0

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

        if asbly.save
          etp_delete_counter += 1 if etp.destroy
        end
      end
    end

    # migrate extrapolate_component_parts into assemblies
    ecp_start_count = ExtrapolateComponentPart.all.size
    ecp_delete_counter = 0

    ExtrapolateComponentPart.all.each do |e|
      asbly = Assembly.find_or_initialize_by(
        combination_id: e.component_id,
        combination_type: 'Component',
        item_id: e.part_id,
        item_type: 'Part'
      )

      next unless asbly.new_record?

      asbly.quantity = e.parts_per_component
      if asbly.save
        ecp_delete_counter += 1 if e.destroy
      end
    end

    # migrate extrapolate_technology_components into assemblies
    etc_start_count = ExtrapolateTechnologyComponent.all.size
    etc_delete_counter = 0

    # Start by making assemblies for required components,
    # they are the "primary" components
    # the remaining ETCs are all for "subcomponents"
    ExtrapolateTechnologyComponent.required.each do |e|
      # don't make assemblies for the duplicated components
      next if e.component.completed_tech?

      asbly = Assembly.find_or_initialize_by(
        combination_type: 'Technology',
        combination_id: e.technology_id,
        item_type: 'Component',
        item_id: e.component_id
      )

      next unless asbly.new_record?

      asbly.quantity = e.components_per_technology
      if asbly.save
        etc_delete_counter += 1 if e.destroy
      end
    end

    # and simplify the join table beetween Materials and Parts
    create_table :materials_parts, id: false do |t|
      t.belongs_to :part
      t.belongs_to :material
      t.decimal :quantity, precision: 8, scale: 4, default: 1, null: false
    end

    add_index :materials_parts, [:part_id, :material_id]

    emp_start_count = ExtrapolateMaterialPart.all.size
    emp_delete_counter = 0

    ExtrapolateMaterialPart.all.each do |e|
      mp = MaterialsPart.find_or_initialize_by(
        part_id: e.part_id,
        material_id: e.material_id
      )

      next unless mp.new_record?

      mp.quantity = e.parts_per_material
      if mp.save
        emp_delete_counter += 1 if e.destroy
      end
    end

    etp_end_count = ExtrapolateTechnologyPart.all.size
    ecp_end_count = ExtrapolateComponentPart.all.size
    etc_end_count = ExtrapolateTechnologyComponent.all.size
    emp_end_count = ExtrapolateMaterialPart.all.size

    puts 'Results:'
    puts '-------------------------------------------------------'
    puts 'ExtrapolateTechnologyPart:'
    puts "Start count: #{etp_start_count}"
    puts "Deletion counter: #{etp_delete_counter}"
    puts "Remaining count (duplicative): #{etp_end_count}"
    puts '-------------------------------------------------------'
    puts 'ExtrapolateComponentPart:'
    puts "Start count: #{ecp_start_count}"
    puts "Deletion counter: #{ecp_delete_counter}"
    puts "Remaining count: #{ecp_end_count}"
    puts '-------------------------------------------------------'
    puts 'ExtrapolateTechnologyComponent:'
    puts "Start count: #{etc_start_count}"
    puts "Deletion counter: #{etc_delete_counter}"
    puts "Remaining count (subcomponents): #{etc_end_count}"
    puts '-------------------------------------------------------'
    puts 'ExtrapolateMaterialPart:'
    puts "Start count: #{emp_start_count}"
    puts "Deletion counter: #{emp_delete_counter}"
    puts "Remaining count: #{emp_end_count}"
    puts '-------------------------------------------------------'
    puts 'Manually creating known subcomponents:'
    # SAM3 Sand pre-filter
    Assembly.create!(
      [
        { combination_type: 'Component', combination_id: 22, item_type: 'Component', item_id: 31 },
        { combination_type: 'Component', combination_id: 22, item_type: 'Component', item_id: 29 },
        { combination_type: 'Component', combination_id: 29, item_type: 'Component', item_id: 43 },
        { combination_type: 'Component', combination_id: 31, item_type: 'Component', item_id: 30 }
      ]
    )
    puts '-------------------------------------------------------'
    puts 'Clean up duplicate assembly items (for SAM3 only):'
    Technology.find(3).assemblies.where(item_type: 'Component').each { |a| a.remove_duplicates! }

    # destroy ExtrapolateComponentPart table only if all records are transferred
    # drop_table 'extrapolate_component_parts' if ExtrapolateComponentPart.all.size.zero?

    # destroy ExtrapolateTechnologyComponent table only if all records are transferred
    # drop_table 'extrapolate_technology_components' if ExtrapolateTechnologyComponent.all.size.zero?

    # the remaining records in ExtrapolateTechnologyPart are duplicative
    # drop_table 'extrapolate_technology_parts'

    # destroy ExtrapolateMaterialPart table only if all records are transferred
    # drop_table 'extrapolate_material_parts' if ExtrapolateMaterialPart.all.size.zero?
  end
end
