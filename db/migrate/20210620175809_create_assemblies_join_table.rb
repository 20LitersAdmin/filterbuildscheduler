# frozen_string_literal: true

class CreateAssembliesJoinTable < ActiveRecord::Migration[6.1]
  def change
    # create the polymorphic join table used to link Technologies, Components and Parts
    # combination: the "parent" nodel
    # item: the "child" node
    # quantity: number of items per combination
    # priority: makes Assemblies orderable via item_type: { 'Component' => 0, 'Part' => 1 }
    create_table :assemblies do |t|
      t.bigint   :combination_id,   null: false
      t.string   :combination_type, null: false
      t.bigint   :item_id,          null: false
      t.string   :item_type,        null: false
      t.integer  :quantity,         null: false, default: 1
      t.monetize :price
      t.integer  :depth
    end

    add_index :assemblies, [:item_id, :item_type]
    add_index :assemblies, [:combination_id, :combination_type]

    # simplify the join table beetween Materials and Parts
    # to get `quantity`, call `part.quantity_from_material`
    create_table :materials_parts do |t|
      t.belongs_to :material
      t.belongs_to :part
      t.decimal :quantity, precision: 8, scale: 4, default: 1, null: false
    end

    add_index :materials_parts, [:part_id, :material_id], unique: true

    ActiveRecord::Base.logger.level = 1

    # shorten Technology Names:
    ary = [
      [1, 'VF100'],
      [2, 'VF500'],
      [3, 'SAM3'],
      [4, 'VF200'],
      [7, 'SAM2'],
      [8, 'Pump']
    ]
    ary.each do |i|
      Technology.find(i[0]).update(short_name: i[1])
    end

    puts 'delete obsolete items before creating assemblies'
    moot_parts = [1, 20, 21, 24, 26, 30, 32, 45, 46, 47, 48, 49, 51, 52, 53, 54, 55, 57, 58, 62, 64, 65, 111]
    ExtrapolateMaterialPart.where(part_id: moot_parts).destroy_all
    ExtrapolateTechnologyPart.where(part_id: moot_parts).destroy_all
    ExtrapolateComponentPart.where(part_id: moot_parts).destroy_all
    Part.where(id: moot_parts).destroy_all

    ExtrapolateTechnologyComponent.where(component_id: [7, 11]).destroy_all
    ExtrapolateComponentPart.where(component_id: [7, 11]).destroy_all
    Component.where(id: [7, 11]).destroy_all

    puts 'deal with the single case of a Material being used directly in a Technology'
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

    puts 'deal with the single case of a Material being used directly in a Technology'
    ExtrapolateMaterialPart.all.each do |e|
      mp = MaterialsPart.find_or_initialize_by(
        part_id: e.part_id,
        material_id: e.material_id
      )

      mp.quantity = e.parts_per_material
      e.destroy if mp.save
    end

    puts 'create assemblies for Parts in Technologies (NOT parts in Components, which are in Technologies)'
    # THIS IS DONE FIRST because it relies upon existing join table records
    # If it's run later, those records are already deleted and duplicates are created around the tree
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
        etp.destroy if asbly.save
      end
    end

    puts 'destroy Component.where(completed_tech: true)'
    completed_comps = Component.where(completed_tech: true)
    ExtrapolateComponentPart.where(component_id: completed_comps.pluck(:id)).destroy_all

    ExtrapolateTechnologyComponent.where(component_id: completed_comps.pluck(:id)).destroy_all

    completed_comps.destroy_all

    puts 'migrate extrapolate_component_parts into assemblies'
    ExtrapolateComponentPart.all.each do |e|
      asbly = Assembly.find_or_initialize_by(
        combination_id: e.component_id,
        combination_type: 'Component',
        item_id: e.part_id,
        item_type: 'Part'
      )

      next unless asbly.new_record?

      asbly.quantity = e.parts_per_component
      e.destroy if asbly.save
    end

    puts 'migrate extrapolate_technology_components into assemblies'
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
      e.destroy if asbly.save
    end

    puts 'manually create missing assemblies'
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
    part_ids = [5, 35, 36]
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

    Assembly.where(item_type: 'Component').each(&:remove_duplicates!)

    puts 'drop old extrap tables'
    # destroy ExtrapolateComponentPart table
    drop_table 'extrapolate_component_parts'
    drop_table 'extrapolate_technology_components'
    # the remaining records in ExtrapolateTechnologyPart are duplicative
    drop_table 'extrapolate_technology_parts'
    # the remaining records in ExtrapolateTechnologyMaterials are duplicative
    drop_table 'extrapolate_technology_materials'
    drop_table 'extrapolate_material_parts'

    puts 'merge *20L* and *VWF* components, parts, and materials'
    # Components: [{1=>"3-inch core with O-rings *VWF*"}, {33=>"3-inch core with O-rings *20L*"}]
    Component.first.replace_with(33).destroy
    Component.find(33).update(name: '3-inch core with O-rings')

    # merge *20L* and *VWF* parts (5 match by name)
    tl_parts = Part.where('name LIKE ?', '%*20L*')
    # tl_parts = [95, 93, 87, 101, 100]
    vwf_parts = Part.where('name LIKE ?', '%*VWF*')
    # vwf_parts = [5, 35, 36, 66, 23, 56, 41, 160, 163, 162, 164, 165, 161, 166]

    # find parts that match by name
    # matching_parts == [16, 22, 6, 3, 2]
    tl_parts.each do |tl|
      matching_part = vwf_parts.where(name: tl.name.gsub('*20L*', '*VWF*')).first

      next unless matching_part.present?

      matching_part.replace_with(tl.id)
      tl.update(name: tl.name.gsub(' *20L*', ''))
      matching_part.destroy
    end

    vwf_parts_again = Part.where('name LIKE ?', '%*VWF*')
    # search for 20L parts that match VWF parts when ' *VWF*' is removed
    # matching_parts == [97, 109]

    vwf_parts_again.each do |vwf|
      matching_part = Part.where(name: vwf.name.gsub(' *VWF*', '')).first

      next unless matching_part.present?

      matching_part.update(name: matching_part.name.gsub(' *20L*', ''))

      # vwf == Part.find(161)
      # vwf.materials == Material.find(2)
      # Part.find(109) is already linked to Material.find(11), so we don't want to link it to Material.find(2)
      vwf.replace_with(matching_part.id) unless matching_part.id == 109
      vwf.destroy
    end

    # drop "*VWF*" from remaining parts
    Part.where('name LIKE ?', '%*VWF*').each do |part|
      part.update(name: part.name.gsub(' *VWF*', ''))
    end

    # merge *20L* and *VWF* materials
    Material.first.replace_with(12).destroy
    Material.find(2).replace_with(11).destroy

    mat = Material.find(12)
    mat.update(name: mat.name.gsub(' *20L*', ''))

    mat = Material.find(11)
    mat.update(name: mat.name.gsub(' *20L*', ''))

    # Calculate quantities of all components, parts and materials on every Technology, calculate depths for all Assemblies
    QuantityAndDepthCalculationJob.perform_now

    # Calculate all prices
    PriceCalculationJob.perform_now

    ActiveRecord::Base.logger.level = 0
  end
end
