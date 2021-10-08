# frozen_string_literal: true

class InventoryMigrationJob < ApplicationJob
  queue_as :inventory_migration

  # Migrations that run before:
  # AddCountsToItemTables
  # CreateAssembliesJoinTable (also creates MaterialsPart)
  # ChangeFromParanoiaToDiscard
  # CreateActiveStorageTables
  # AddBelowMinimumBooleansToItems

  # Migrations that run after:
  # DropItemIdsFromCounts
  # DropExtrapTables
  # ParityForAllItems

  def perform(*_args)
    ActiveRecord::Base.logger.level = 1

    puts '========================= Starting InventoryMigrationJob ========================='

    delete_obsolete_items
    assign_uids_to_items
    change_counts_to_polymorphic
    transfer_latest_count_values_to_items
    add_history_to_every_item
    turn_components_into_technologies_and_delete
    delete_counts
    shorten_technology_names
    create_materials_parts_from_extrap
    delete_all_extraps
    manually_create_assemblies

    puts '========================= FINISHED InventoryMigrationJob ========================='

    ActiveRecord::Base.logger.level = 0
    # Calculate quantities of all components, parts and materials on every Technology, calculate depths for all Assemblies
    QuantityAndDepthCalculationJob.perform_now

    # Calculate all prices
    PriceCalculationJob.perform_now
  end

  def delete_obsolete_items
    puts 'delete obsolete items before creating assemblies'

    moot_mats = [1, 2, 3, 4, 5]
    ExtrapolateMaterialPart.where(material_id: moot_mats).destroy_all
    ExtrapolateTechnologyMaterial.where(material_id: moot_mats).destroy_all
    Count.where(material_id: moot_mats).destroy_all
    Material.where(id: moot_mats).destroy_all

    moot_active_parts = [1, 2, 3, 4, 12, 16, 18, 19, 20, 21, 22, 23, 24, 26, 30, 31, 32, 37, 38, 40, 41, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 61, 62, 63, 64, 65, 87, 111, 161, 162, 163, 164, 165, 166]
    moot_parts = (Part.where.not(discarded_at: nil).pluck(:id) + moot_active_parts).flatten.uniq
    ExtrapolateMaterialPart.where(part_id: moot_parts).destroy_all
    ExtrapolateTechnologyPart.where(part_id: moot_parts).destroy_all
    ExtrapolateComponentPart.where(part_id: moot_parts).destroy_all
    Count.where(part_id: moot_parts).destroy_all
    Part.where(id: moot_parts).destroy_all

    moot_active_comps = [5, 7, 8, 9, 10, 11, 14, 16, 17, 18, 19, 20, 21, 44, 46]
    moot_comps = (Component.where.not(discarded_at: nil).pluck(:id) + moot_active_comps).flatten.uniq
    ExtrapolateTechnologyComponent.where(component_id: moot_comps).destroy_all
    ExtrapolateComponentPart.where(component_id: moot_comps).destroy_all
    Count.where(component_id: moot_comps).destroy_all
    Component.where(id: moot_comps).destroy_all

    moot_techs = [1, 2, 4]
    ExtrapolateTechnologyComponent.where(technology_id: moot_techs).destroy_all
    ExtrapolateTechnologyPart.where(technology_id: moot_techs).destroy_all
    ExtrapolateTechnologyMaterial.where(technology_id: moot_techs).destroy_all
    # Only discard techs because events rely on :technology_id
    Technology.where(id: moot_techs).discard_all
  end

  def assign_uids_to_items
    puts 'assign UIDs to items'
    Technology.update_all(uid: nil)
    Technology.all.each do |t|
      t.update_columns(uid: "T#{t.id.to_s.rjust(3, '0')}")
    end

    Component.update_all(uid: nil)
    Component.all.each do |c|
      c.update_columns(uid: "C#{c.id.to_s.rjust(3, '0')}")
    end

    Part.update_all(uid: nil)
    Part.all.each do |pa|
      pa.update_columns(uid: "P#{pa.id.to_s.rjust(3, '0')}")
    end

    Material.update_all(uid: nil)
    Material.all.each do |m|
      m.update_columns(uid: "M#{m.id.to_s.rjust(3, '0')}")
    end
  end

  def change_counts_to_polymorphic
    puts 'transform counts to polymorphic'

    Count.all.each do |count|
      if count.part_id.present?
        count.item_id = count.part_id
        count.item_type = 'Part'
      elsif count.material_id.present?
        count.item_id = count.material_id
        count.item_type = 'Material'
      else
        count.item_id = count.component_id
        count.item_type = 'Component'
      end
      count.save
    end
  end

  def transfer_latest_count_values_to_items
    puts 'add counts from latest inventory'
    Inventory.latest.counts.each do |count|
      item = count.item

      next unless item.present?

      item.update_columns(
        loose_count: count.loose_count,
        box_count: count.unopened_boxes_count,
        available_count: count.loose_count + (count.unopened_boxes_count * item.quantity_per_box)
      )
    end
  end

  def add_history_to_every_item
    puts 'add history to every item'
    Inventory.order(date: :desc, created_at: :desc).each do |i|
      i.counts.each do |count|
        item = count.item
        next unless item.present?

        item.history[i.date.iso8601] = { loose: count.loose_count, box: count.unopened_boxes_count, available: count.available }

        item.save!
      end
    end
  end

  def turn_components_into_technologies_and_delete
    puts 'transfer counts from Components.where(completed_tech: true) to Technology'
    comps = Component.where(completed_tech: true)
    comps.each do |comp|
      tech = ExtrapolateTechnologyComponent.where(component_id: comp.id).first.technology

      tech.update_columns(
        loose_count: comp.loose_count,
        box_count: comp.box_count,
        available_count: comp.available_count,
        history: comp.history
      )
    end

    ExtrapolateComponentPart.where(component_id: comps.pluck(:id)).destroy_all
    ExtrapolateTechnologyComponent.where(component_id: comps.pluck(:id)).destroy_all

    comps.destroy_all
  end

  def delete_counts
    puts 'Delete all counts'
    Count.delete_all
    ActiveRecord::Base.connection.reset_pk_sequence!('counts')
  end

  def shorten_technology_names
    puts 'shorten technology names'
    ary = [
      [3, 'SAM3'],
      [7, 'SAM2'],
      [8, 'Pump']
    ]
    ary.each do |i|
      Technology.find(i[0]).update(short_name: i[1])
    end
  end

  def create_materials_parts_from_extrap
    # TODO: Check for accuracy
    #  MaterialsPart.all.map(&:name)
    # ["M006::P067",
    #  "M006::P068",
    #  "M006::P069",
    #  "M009::P071",
    #  "M011::P108",
    #  "M011::P109",
    #  "M008::P083",
    #  "M012::P110",
    #  "M011::P158",
    #  "M011::P107"]
    puts 'Turn ExtrapolateMaterialParts into MaterialsParts'
    ExtrapolateMaterialPart.all.each do |e|
      mp = MaterialsPart.find_or_initialize_by(
        part_id: e.part_id,
        material_id: e.material_id
      )

      mp.quantity = e.parts_per_material
      e.destroy if mp.save
    end
  end

  def delete_all_extraps
    puts 'deleting all Extrap records'
    ExtrapolateComponentPart.delete_all
    ExtrapolateMaterialPart.delete_all
    ExtrapolateTechnologyComponent.delete_all
    ExtrapolateTechnologyMaterial.delete_all
    ExtrapolateTechnologyPart.delete_all
  end

  def manually_create_assemblies
    puts 'Manually manage assemblies'

    puts 'build assemblies for T003: Household filter'

    Assembly.create!([
      # T003: Household filter
      {
        combination_id: 3,
        combination_type: 'Technology',
        item_id: 22,
        item_type: 'Component',
        quantity: 1
      },
      {
        combination_id: 3,
        combination_type: 'Technology',
        item_id: 48,
        item_type: 'Component',
        quantity: 1
      },
      {
        combination_id: 3,
        combination_type: 'Technology',
        item_id: 26,
        item_type: 'Component',
        quantity: 1
      },
      {
        combination_id: 3,
        combination_type: 'Technology',
        item_id: 81,
        item_type: 'Part',
        quantity: 1
      },
      # Bucket, lid, sticker
      {
        combination_id: 3,
        combination_type: 'Technology',
        item_id: 86,
        item_type: 'Part',
        quantity: 2
      },
      {
        combination_id: 3,
        combination_type: 'Technology',
        item_id: 85,
        item_type: 'Part',
        quantity: 2
      },
      {
        combination_id: 3,
        combination_type: 'Technology',
        item_id: 92,
        item_type: 'Part',
        quantity: 1
      },
      # C022: Sand Outflow Loop
      {
        combination_id: 22,
        combination_type: 'Component',
        item_id: 29,
        item_type: 'Component',
        quantity: 1
      },
      {
        combination_id: 22,
        combination_type: 'Component',
        item_id: 31,
        item_type: 'Component',
        quantity: 1
      },
      {
        combination_id: 22,
        combination_type: 'Component',
        item_id: 67,
        item_type: 'Part',
        quantity: 1
      },
      #   C043: 1/2-inch Screen Cap
      {
        combination_id: 43,
        combination_type: 'Component',
        item_id: 71,
        item_type: 'Part',
        quantity: 1
      },
      {
        combination_id: 43,
        combination_type: 'Component',
        item_id: 75,
        item_type: 'Part',
        quantity: 1
      },
      #   C030: 1/2-inch Bulkhead Assembly
      {
        combination_id: 30,
        combination_type: 'Component',
        item_id: 73,
        item_type: 'Part',
        quantity: 1
      },
      {
        combination_id: 30,
        combination_type: 'Component',
        item_id: 42,
        item_type: 'Part',
        quantity: 1
      },
      {
        combination_id: 30,
        combination_type: 'Component',
        item_id: 168,
        item_type: 'Part',
        quantity: 1
      },
      {
        combination_id: 30,
        combination_type: 'Component',
        item_id: 74,
        item_type: 'Part',
        quantity: 1
      },
      #   C031: Red Component
      {
        combination_id: 31,
        combination_type: 'Component',
        item_id: 72,
        item_type: 'Part',
        quantity: 1
      },
      {
        combination_id: 31,
        combination_type: 'Component',
        item_id: 69,
        item_type: 'Part',
        quantity: 1
      },
      {
        combination_id: 31,
        combination_type: 'Component',
        item_id: 30,
        item_type: 'Component',
        quantity: 1
      },
      #   C029: Blue Component
      {
        combination_id: 29,
        combination_type: 'Component',
        item_id: 72,
        item_type: 'Part',
        quantity: 1
      },
      {
        combination_id: 29,
        combination_type: 'Component',
        item_id: 68,
        item_type: 'Part',
        quantity: 1
      },
      {
        combination_id: 29,
        combination_type: 'Component',
        item_id: 43,
        item_type: 'Component',
        quantity: 1
      },
      # C048: 3-inch Cartridge w/ Faucet
      #   C050: 3-inch Housing Body w/ O-ring
      {
        combination_id: 50,
        combination_type: 'Component',
        item_id: 7,
        item_type: 'Part',
        quantity: 1
      },
      {
        combination_id: 50,
        combination_type: 'Component',
        item_id: 66,
        item_type: 'Part',
        quantity: 1
      },
      #   C049: 3-inch Cartridge w/ Thick O-ring
      {
        combination_id: 49,
        combination_type: 'Component',
        item_id: 5,
        item_type: 'Part',
        quantity: 1
      },
      {
        combination_id: 49,
        combination_type: 'Component',
        item_id: 35,
        item_type: 'Part',
        quantity: 1
      },
      #   C033: 3-inch cartridge w/ O-rings
      {
        combination_id: 33,
        combination_type: 'Component',
        item_id: 49,
        item_type: 'Component',
        quantity: 1
      },
      {
        combination_id: 33,
        combination_type: 'Component',
        item_id: 36,
        item_type: 'Part',
        quantity: 1
      },
      #   C023: 3-inch Membrane Cartridge
      {
        combination_id: 23,
        combination_type: 'Component',
        item_id: 50,
        item_type: 'Component',
        quantity: 1
      },
      {
        combination_id: 23,
        combination_type: 'Component',
        item_id: 33,
        item_type: 'Component',
        quantity: 1
      },
      {
        combination_id: 23,
        combination_type: 'Component',
        item_id: 8,
        item_type: 'Part',
        quantity: 1
      },
      #   C024: Faucet w/ Washers
      {
        combination_id: 24,
        combination_type: 'Component',
        item_id: 79,
        item_type: 'Part',
        quantity: 1
      },
      {
        combination_id: 24,
        combination_type: 'Component',
        item_id: 168,
        item_type: 'Part',
        quantity: 1
      },
      {
        combination_id: 24,
        combination_type: 'Component',
        item_id: 42,
        item_type: 'Part',
        quantity: 1
      },
      #   C048: 3-inch Membrane Cartridge w/ Faucet
      {
        combination_id: 48,
        combination_type: 'Component',
        item_id: 112,
        item_type: 'Part',
        quantity: 1
      },
      {
        combination_id: 48,
        combination_type: 'Component',
        item_id: 24,
        item_type: 'Component',
        quantity: 1
      },
      {
        combination_id: 48,
        combination_type: 'Component',
        item_id: 23,
        item_type: 'Component',
        quantity: 1
      },
      #  C026: SAM3 Backflush Assembly  17
      {
        combination_id: 26,
        combination_type: 'Component',
        item_id: 83,
        item_type: 'Part',
        quantity: 1
      },
      {
        combination_id: 26,
        combination_type: 'Component',
        item_id: 84,
        item_type: 'Part',
        quantity: 1
      },
      {
        combination_id: 26,
        combination_type: 'Component',
        item_id: 82,
        item_type: 'Part',
        quantity: 1
      },
    ])

    puts 'build assemblies for T010: Modified SAM3'

    Component.find(47).update(name: '3-inch Cartridge w/ Elbow')

    elbow_bulkhead = Component.create!(
      name: 'Nylon Elbow Bulkhead Assembly',
      description: '1/2-inch nylon elbow with washers and locknut',
      only_loose: true
    )

    Assembly.create!(
      [
        {
          combination_id: 10,
          combination_type: 'Technology',
          item_id: 47,
          item_type: 'Component',
          quantity: 2
        },
        # Bucket, lid, sticker
        {
          combination_id: 10,
          combination_type: 'Technology',
          item_id: 86,
          item_type: 'Part',
          quantity: 2
        },
        {
          combination_id: 10,
          combination_type: 'Technology',
          item_id: 85,
          item_type: 'Part',
          quantity: 2
        },
        {
          combination_id: 10,
          combination_type: 'Technology',
          item_id: 92,
          item_type: 'Part',
          quantity: 1
        },
        # cartridge w/ elbow
        {
          combination_id: 47,
          combination_type: 'Component',
          item_id: elbow_bulkhead.id,
          item_type: 'Component'
        },
        {
          combination_id: 47,
          combination_type: 'Component',
          item_id: 23,
          item_type: 'Component'
        },
        # elbow bulkhead
        {
          combination_id: elbow_bulkhead.id,
          combination_type: 'Component',
          item_id: 167,
          item_type: 'Part',
          quantity: 1
        },
        {
          combination_id: elbow_bulkhead.id,
          combination_type: 'Component',
          item_id: 42,
          item_type: 'Part',
          quantity: 1
        },
        {
          combination_id: elbow_bulkhead.id,
          combination_type: 'Component',
          item_id: 168,
          item_type: 'Part',
          quantity: 1
        },
        {
          combination_id: elbow_bulkhead.id,
          combination_type: 'Component',
          item_id: 74,
          item_type: 'Part',
          quantity: 1
        }
      ]
    )

    puts 'build assemblies for T008: Handpump'

    Assembly.create!(
      [
        {
          combination_id: 8,
          combination_type: 'Technology',
          item_id: 148,
          item_type: 'Part',
          quantity: 1
        },
        {
          combination_id: 8,
          combination_type: 'Technology',
          item_id: 147,
          item_type: 'Part',
          quantity: 1
        },
        {
          combination_id: 8,
          combination_type: 'Technology',
          item_id: 146,
          item_type: 'Part',
          quantity: 2
        },
        {
          combination_id: 8,
          combination_type: 'Technology',
          item_id: 145,
          item_type: 'Part',
          quantity: 1
        }
      ]
    )

    puts 'build assemblies for T009: RWHS'

    Assembly.create!(
      [
        {
          combination_id: 9,
          combination_type: 'Technology',
          item_id: 149,
          item_type: 'Part',
          quantity: 1
        },
        {
          combination_id: 9,
          combination_type: 'Technology',
          item_id: 150,
          item_type: 'Part',
          quantity: 1
        },
        {
          combination_id: 9,
          combination_type: 'Technology',
          item_id: 98,
          item_type: 'Part',
          quantity: 1
        },
        {
          combination_id: 9,
          combination_type: 'Technology',
          item_id: 154,
          item_type: 'Part',
          quantity: 1
        },
        {
          combination_id: 9,
          combination_type: 'Technology',
          item_id: 152,
          item_type: 'Part',
          quantity: 1
        },
        {
          combination_id: 9,
          combination_type: 'Technology',
          item_id: 153,
          item_type: 'Part',
          quantity: 1
        },
        {
          combination_id: 9,
          combination_type: 'Technology',
          item_id: 151,
          item_type: 'Part',
          quantity: 2
        },
        {
          combination_id: 9,
          combination_type: 'Technology',
          item_id: 156,
          item_type: 'Part',
          quantity: 2
        },
        {
          combination_id: 9,
          combination_type: 'Technology',
          item_id: 97,
          item_type: 'Part',
          quantity: 3
        },
        {
          combination_id: 9,
          combination_type: 'Technology',
          item_id: 96,
          item_type: 'Part',
          quantity: 1
        },
        {
          combination_id: 9,
          combination_type: 'Technology',
          item_id: 103,
          item_type: 'Part',
          quantity: 1
        },
        {
          combination_id: 9,
          combination_type: 'Technology',
          item_id: 158,
          item_type: 'Part',
          quantity: 1
        },
        {
          combination_id: 9,
          combination_type: 'Technology',
          item_id: 155,
          item_type: 'Part',
          quantity: 1
        },
        {
          combination_id: 9,
          combination_type: 'Technology',
          item_id: 157,
          item_type: 'Part',
          quantity: 1
        }
      ]
    )

    puts 'TODO: build assemblies for T007: SAM2'
  end
end
