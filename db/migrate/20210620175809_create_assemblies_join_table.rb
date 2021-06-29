# frozen_string_literal: true

class CreateAssembliesJoinTable < ActiveRecord::Migration[6.1]
  def change
    # create the polymorphic join table used to link Technologies, Components and Parts
    # combination: the "parent" nodel
    # item: the "child" node
    # quantity: number of items per combination
    # priority: makes Assemblies orderable via item_type: { 'Component' => 0, 'Part' => 1 }
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

    # delete obsolete items before creating assemblies
    moot_parts = [1, 20, 21, 24, 26, 45, 46, 47, 48, 49, 51, 52, 53, 54, 55, 57, 58, 62, 64, 65, 111]
    ExtrapolateMaterialPart.where(part_id: moot_parts).destroy_all
    ExtrapolateTechnologyPart.where(part_id: moot_parts).destroy_all
    ExtrapolateComponentPart.where(part_id: moot_parts).destroy_all
    Part.where(id: moot_parts).destroy_all

    ExtrapolateTechnologyComponent.where(component_id: 7).destroy_all
    ExtrapolateComponentPart.where(component_id: 7).destroy_all
    Component.find(7).destroy

    # create assemblies for Parts in Technologies (NOT parts in Components, which are in Technologies)
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
      if e.component.completed_tech?
        e.destroy
        next
      end

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

    # deal with the single case of a Material being used directly in a Technology:
    # M005 Tubing 1/4-inch x 12-inch L
    # solution: transform it into a Part
    m = Material.find(5)
    Part.create!(m.attributes.except('id'))
    # add the new part's assembly
    Assembly.create!(combination: Technology.first, item: Part.last)

    # ensure there are no old relationships
    ExtrapolateMaterialPart.where(material_id: 5).destroy_all
    # P040 Tubing 1/4-inch x 2-inch L was the Part that was made from this material
    Part.find(40).update_columns(made_from_materials: false)
    m.destroy

    # simplify the join table beetween Materials and Parts
    # to get `quantity`, call `part.quantity_from_material`
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
    # SAM3 Sand pre-filter, all quantities are 1
    Assembly.create!(
      [
        { combination_type: 'Component', combination_id: 22, item_type: 'Component', item_id: 31 },
        { combination_type: 'Component', combination_id: 22, item_type: 'Component', item_id: 29 },
        { combination_type: 'Component', combination_id: 29, item_type: 'Component', item_id: 43 },
        { combination_type: 'Component', combination_id: 31, item_type: 'Component', item_id: 30 }
      ]
    )
    # SAM3 Micro-filter:
    Assembly.create!(combination: Component.find(23), item_type: 'Component', item_id: 2)
    # C001 VF100 3-inch core w/ O-rings, all quantites are 1
    # Instead of creating, find and edit, since the relationships are all shallow in production data
    part_ids = [5, 35, 56]
    Assembly.where(combination: Technology.first, item_type: 'Part', item_id: part_ids).update_all(combination_type: 'Component', combination_id: 1)
    # C002 VF100 cartridge unwelded, all quantities are 1
    Assembly.create!(
      [
        { combination_type: 'Component', combination_id: 2, item_type: 'Component', item_id: 1 },
        { combination_type: 'Component', combination_id: 2, item_type: 'Part', item_id: 7 },
        { combination_type: 'Component', combination_id: 2, item_type: 'Part', item_id: 8 },
        { combination_type: 'Component', combination_id: 2, item_type: 'Part', item_id: 66 }
      ]
    )
    # C003 VF100 cartridge welded, has only C002
    Assembly.create!(combination_type: 'Component', combination_id: 3, item_type: 'Component', item_id: 2)

    # C012 VF100 bag w/ instruction, all quantities are 1
    # Instead of creating, find and edit, since the relationships are all shallow in production data
    part_ids = [11, 17]
    Assembly.where(combination: Technology.first, item_type: 'Part', item_id: part_ids).update_all(combination_type: 'Component', combination_id: 12)

    # VF500 - 12-inch O-rings should be inside C016
    Assembly.where(combination: Technology.second, item: Part.find(90)).first.update(combination_type: 'Component', combination_id: 16, quantity: 1)

    # Modified SAM3
    Assembly.create!(combination_type: 'Technology', combination_id: 10, item_type: 'Component', item_id: 2)

    puts '-------------------------------------------------------'
    puts 'Clean up duplicate assembly items:'
    Assembly.where(item_type: 'Component').each(&:remove_duplicates!)

    # destroy ExtrapolateComponentPart table
    drop_table 'extrapolate_component_parts'

    # destroy ExtrapolateTechnologyComponent table only if all records are transferred
    drop_table 'extrapolate_technology_components'

    # the remaining records in ExtrapolateTechnologyPart are duplicative
    drop_table 'extrapolate_technology_parts'

    # destroy ExtrapolateMaterialPart table
    # drop_table 'extrapolate_material_parts' if ExtrapolateMaterialPart.all.size.zero?
  end
end
