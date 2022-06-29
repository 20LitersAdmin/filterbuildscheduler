# frozen_string_literal: true

class EventInventoryJob < ApplicationJob
  queue_as :event_inventory

  attr_accessor :inventory, :loose_created, :box_created, :technology, :produced_and_boxed, :item

  def perform(event)
    # ProduceableJob sets all item.can_be_produced values, and is run by Inventory#after_update callback
    # so we can assume item.can_be_produced is accurate from the latest inventory

    @event         = event
    @loose_created = @event.technologies_built
    @box_created   = @event.boxes_packed

    # escape clause to ensure some result from event
    return false unless @loose_created.positive? || @box_created.positive?

    # Event#has_one Inventory, so escape if it's already been performed.
    return false if @event.inventory.present?

    @technology         = event.technology
    @produced_and_boxed = @box_created * @technology.quantity_per_box
    @produced_total     = @produced_and_boxed + @loose_created

    @inventory = @event.create_inventory(date: Date.today, technologies: [@technology.id])

    # If boxes were packed and there were enough @technology loose items,
    # we assume the loose items were just boxed, nothing had to be produced
    technology_has_sufficient_loose_count = @box_created.positive? && (@technology.loose_count > @produced_and_boxed)

    create_technology_count_only if technology_has_sufficient_loose_count

    unless technology_has_sufficient_loose_count?
      # @technology couldn't handle it alone, time to rely on the tree
      # Create a count for Technology that results in @technology.loose_count == @loose_created && @technology.box_count += @box_created
      create_technology_count

      # @remainder_needed is set and represents what we still need to "produce" from sub items
      @technology_remainder = @produced_total - @technology.loose_count
      loop_assemblies(@technology, @technology_remainder)
    end

    @inventory.update(completed_at: Time.now)
    @inventory.reload.run_count_transfer_job
  end

  def create_count(item, loose_count, box_count)
    # KEEP IN MIND: the count values should not be the desired values, but instead the amount to add or subtract from the item to achieve the desired values
    # see CountTransferJob#transfer_auto_count

    @inventory.counts.create(
      item: item,
      loose_count: loose_count,
      unopened_boxes_count: box_count
    )
  end

  def create_technology_count
    # we assume that previous @technology.loose_count were used towards @produced_total, but were insufficient to fully satisfy @produced_total.
    #
    # we assume that the @event.technologies_built is now the new value for @technology.loose_count
    change_to_loose = @loose_created - @technology.loose_count

    # KEEP IN MIND: the count values should not be the new values, but instead the amount to add or subtract from the item
    create_count(@technology, change_to_loose, @box_created)
  end

  def create_technology_count_only
    # we assume that the @event.boxes_packed are all new and added to the existing total
    #   @technology.box_count += @box_created
    # we assume that previous @technology.loose_count were used to achieve @box_created and any remainder are added with what loose items were produced
    #   @technology.loose_count = (@technology.loose_count - @produced_and_boxed) + @loose_created
    new_loose_count = @loose_created - @produced_and_boxed

    # KEEP IN MIND: the count values should not be the new values, but instead the amount to add or subtract from the item
    create_count(@technology, new_loose_count, @box_created)
  end

  def item_can_satisfy_remainder(amt_to_remove)
    # 1. item_can_satisfy_remainder
    # - create a count that subtracts the amt_to_remove from the item's current counts

    if @item.loose_count >= amt_to_remove
      # There are enough loose items, no boxes need to be opened
      create_count(@item, -amt_to_remove, 0)
    else
      item_quantity_per_box = @item.quantity_per_box
      # There aren't enough loose items, need to open boxes

      # calculate number of boxes that need to be opened
      needed_from_boxed = amt_to_remove - @item.loose_count
      boxes_to_open = (needed_from_boxed / item_quantity_per_box.to_f).ceil

      # determine how this will change the loose count
      change_to_loose = (boxes_to_open * item_quantity_per_box) - amt_to_remove

      create_count(@item, change_to_loose, -boxes_to_open)

      # no need to traverse down any farther
    end
  end

  def item_has_sub_assemblies(amt_to_remove)
    # 3. item_insufficient (but has_sub_assemblies)
    # - a count was already created by #item_insufficient to zero out the counts
    # - set a new remainder and traverse down

    remainder = amt_to_remove - @item.available_count

    if @item.is_a?(Part)
      produce_from_material(@item, remainder)
    else
      loop_assemblies(@item, remainder)
    end
  end

  def item_insufficient
    # zero out the item counts, everything was used
    create_count(@item, -@item.loose_count, -@item.box_count)
  end

  def loop_assemblies(combination, remainder)
    assemblies = Assembly.without_price_only.where(combination: combination)

    assemblies.each do |assembly|
      @item = assembly.item
      quantity_per_assembly = assembly.quantity

      to_remove = remainder * quantity_per_assembly

      # Three scenarios:
      # 1. item_can_satisfy_remainder
      # 2. item_insufficient (and has_no_sub_assemblies)
      # 3. item_insufficient (but has_sub_assemblies)

      if @item.available_count >= to_remove
        item_can_satisfy_remainder(to_remove)
      else
        # creates a count that zeros out the @item.loose_count and @item.box_count
        item_insufficient

        # prepares for next level of tree traversal
        item_has_sub_assemblies(to_remove) if @item.has_sub_assemblies?
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

      create_count(material, change_to_material_loose, -boxes_to_open)
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
      create_count(material, -material.loose_count, -material.box_count)
    end
  end
end
