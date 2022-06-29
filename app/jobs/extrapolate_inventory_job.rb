# frozen_string_literal: true

class ExtrapolateInventoryJob < ApplicationJob
  queue_as :extrapolate_inventory

  def perform(inventory)
    return false unless inventory.extrapolate? &&
                          inventory.counts.positive? &&
                          inventory.completed_at.blank?

    @inventory = inventory

    # ProduceableJob sets all item.can_be_produced values, and is run by Inventory#after_update callback
    # so we can assume item.can_be_produced is accurate from the latest inventory

    # handle changes in Component inventory counts first, so that these new changes can be incorporated into Technology changes
    comp_counts = @inventory.counts.components

    comp_counts.each do |comp_count|
      next if comp_count.useless?

      component = comp_count.item

      if item_has_sufficient_loose_count?(comp_count)
        adjust_count_only(comp_count, component, produced_and_boxed)
      else
        # component couldn't handle it alone, time to rely on the tree

        # remainder needed is set and represents what we still need to "produce" from sub items
        component_remainder = produced_total - technology.loose_count

        loop_assemblies(technology, component_remainder)
      end
    end

    # handle changes in Technology inventory counts after Component inventory counts
    tech_counts = @inventory.counts.technologies

    tech_counts.each do |tech_count|
      next if tech_count.useless?

      technology = tech_count.item

      if item_has_sufficient_loose_count?(tech_count)
        adjust_count_only(tech_count, technology, produced_and_boxed)
      else
        # technology couldn't handle it alone, time to rely on the tree

        # remainder needed is set and represents what we still need to "produce" from sub items
        technology_remainder = produced_total - technology.loose_count

        loop_assemblies(technology, technology_remainder)
      end

      # run CountTransferJob
    end
  end

  def adjust_tech_count(tech_count)
    # needed??
  end

  def adjust_count_only(count, item, produced_and_boxed)
    # increase the count's box_count by the item's box_count
    count.unopened_boxes_count += item.box_count

    # adjust the count's loose_count by adding what was created as loose and subtracting what was boxed
    count.loose_count += item.loose_count - produced_and_boxed
  end

  def create_or_update_count(item, loose_count, box_count)
    # KEEP IN MIND: the count values should not be the desired values, but instead the amount to add or subtract from the item to achieve the desired values
    # see CountTransferJob#transfer_auto_count
    count = @inventory.counts.find_or_initialize_by(item: item)

    count.tap do |c|
      c.loose_count += loose_count
      c.box_count += box_count
    end

    count.save
  end

  def item_can_satisfy_remainder(item, amt_to_remove)
    # 1. item_can_satisfy_remainder
    # - create or update a count that subtracts the amt_to_remove from the item's current counts

    if item.loose_count >= amt_to_remove
      # There are enough loose items, no boxes need to be opened
      create_or_update_count(item, -amt_to_remove, 0)
    else
      item_quantity_per_box = item.quantity_per_box
      # There aren't enough loose items, need to open boxes

      # calculate number of boxes that need to be opened
      needed_from_boxed = amt_to_remove - item.loose_count
      boxes_to_open = (needed_from_boxed / item_quantity_per_box.to_f).ceil

      # determine how this will change the loose count
      change_to_loose = (boxes_to_open * item_quantity_per_box) - amt_to_remove

      create_or_update_count(item, change_to_loose, -boxes_to_open)

      # no need to traverse down any farther
    end
  end

  def item_has_sub_assemblies(item, amt_to_remove)
    # 3. item_insufficient (but has_sub_assemblies)
    # - a count was already created by #item_insufficient to zero out the counts
    # - set a new remainder and traverse down

    remainder = amt_to_remove - item.available_count

    if item.is_a?(Part)
      produce_from_material(item, remainder)
    else
      loop_assemblies(item, remainder)
    end
  end

  def item_has_sufficient_loose_count?(count)
    # Can the number of loose and boxed items be satisfied by the existing loose_count of the item?
    item = count.item
    produced_and_boxed = count.unopened_boxes_count * item.quantity_per_box
    produced_total = produced_and_boxed + count.loose_count

    produced_total < item.loose_count
  end

  def item_insufficient(item)
    # zero out the item counts, everything was used
    create_or_update_count(item, -item.loose_count, -item.box_count)
  end

  def loop_assemblies(combination, remainder)
    assemblies = Assembly.without_price_only.where(combination: combination)

    assemblies.each do |assembly|
      item = assembly.item
      quantity_per_assembly = assembly.quantity

      to_remove = remander * quantity_per_assembly

      # Three scenarios:
      # 1. item_can_satisfy_remainder
      # 2. item_insufficient (and has_no_sub_assemblies)
      # 3. item_insufficient (but has_sub_assemblies)

      if item.available_count >= to_remove
        item_can_satisfy_remainder(item, to_remove)
      else
        # finds or creates a count that zeros out the @item.loose_count and @item.box_count
        item_insufficient(item)

        # prepares for next level of tree traversal
        item_has_sub_assemblies(item, to_remove) if item.has_sub_assemblies?
      end
    end
  end

  def material_can_satisfy_remainder(part, parts_needed)
    # Assume whole materials are used, which can lead to the part count needing to be adjusted upwards - to compensate for the material producing more parts than are needed to satisfy the remainder
    material = part.material
    part_quantity_from_material = part.quantity_from_material
    material_needed = (parts_needed / part_quantity_from_material.to_f).ceil
    material_loose = material.loose_count

    if material_loose >= material_needed
      # there are enough loose materials, no boxes need to be opened
      create_count(material, -material_needed, 0)
    else
      material_needed_from_boxed = material_needed - material_loose
      material_quantity_per_box = material.quantity_per_box
      boxes_to_open = (material_needed_from_boxed / material_quantity_per_box.to_f).ceil

      # determine how this will change the material loose count
      change_to_material_loose = (boxes_to_open * material_quantity_per_box) - material_needed

      create_or_update_count(material, change_to_material_loose, -boxes_to_open)
    end

    parts_produced = material_needed * part_quantity_from_material

    return unless parts_produced > parts_needed
    # add extra parts produced from material to the part's count
    count = @inventory.counts.where(item: part).first
    count.loose_count += parts_produced - parts_needed
    count.save
  end

  def produce_from_material(part, remainder)
    # this is the alternative to #loop_assemblies and can only be one node deep (material is the bottom), so no loop necessary
    material = part.material
    parts_produceable = material.available_count * part.quantity_from_material

    if parts_produceable >= remainder
      # send part because part has_one material, but material has_many parts
      # otherwise, we couldn't re-locate the part with confidence
      material_can_satisfy_remainder(part, remainder)
    else
      # zero out material, nothing else can be done
      create_or_update_count(material, -material.loose_count, -material.box_count)
    end
  end
end
