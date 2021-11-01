# frozen_string_literal: true

class EventInventoryJob < ApplicationJob
  queue_as :event_inventory

  def perform(event)
    # ProduceableJob is run by Inventory#after_udate callback
    # so we can assume item.can_be_produced is accurate from the latest inventory

    @event          = event
    @loose_created  = @event.technologies_built
    @box_created    = @event.boxes_packed
    @technology     = event.technology

    @produced_and_boxed = (@box_created * @technology_quantity_per_box)
    @produced_total     = @produced_and_boxed + @loose_created

    @inventory = @event.create_inventory(date: Date.today)

    # Option 1: There were enough existing @technology loose items, they were just boxed, nothing had to be produced
    technology_has_sufficient_loose_count = @technology.loose_count > @produced_and_boxed
    create_technology_count_only if technology_has_sufficient_loose_count

    # sloppy early return
    return true if technology_has_sufficient_loose_count

    # @technology couldn't handle it alone, time to rely on the tree
    # Create a count for Technology that results in @technology.loose_count == @loose_created && @technology.box_count += @box_created
    create_technology_count

    # @remainder_needed is set and represents what we still need to "produce" from sub items
    @technology_remainder = @produced_total - @technology.loose_count
    loop_assemblies(@technology, @technology_remainder)

    # run @inventory.update to trigger CountTransfer job:
    # @inventory.update(completed_at: Time.now)
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
    create_count(@technology, change_to_loose, @box_created)
  end

  def create_technology_count_only
    # we assume that the @event.boxes_packed are all new and added to the existing total
    #   @technology.box_count += @box_created
    # we assume that previous @technology.loose_count were used to achieve @box_created and any remainder are added with what loose items were produced
    #   @technology.loose_count = (@technology.loose_count - @produced_and_boxed) + @loose_created

    # KEEP IN MIND: the count values should not be the new values, but instead the amount to add or subtract from the item

    new_loose_count = @loose_created - @produced_and_boxed
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
      change_to_loose = (boxes_to_open * quantity_per_box) - amt_to_remove

      create_count(@item, change_to_loose, -boxes_to_open)

      # no need to traverse down any farther
    end
  end

  def item_has_sub_assemblies(amt_to_remove)
    # 2. item_insufficient (but has_sub_assemblies)
    # - a count was already created by #item_insufficient to zero out the counts
    # - set a new remainder and traverse down

    remainder = amt_to_remove - @item.available_count
    loop_assemblies(combination, remainder)
  end

  def item_insufficient
    # 3. item_insufficient (and has_no_sub_assemblies)
    # - the item quantities are zeroed out and there's nothing else to do.

    # zero out the item counts, everything was used
    create_count(@item, -@item.loose_count, -@item.box_count)
  end

  def loop_assemblies(combination, remainder)
    assemblies = Assembly.without_price_only.where(combination: combination)

    assemblies.each do |assembly|
      @item = assembly.item
      quantity_per_assembly = assembly.quantity

      # or is it better to rely on @item.quantities[@technology.uid]
      to_remove = remainder * quantity_per_assembly

      # Three scenarios:
      # 1. item_can_satisfy_remainder: (item.available_count / assembly.quantity) >= @remainder
      # 2. item_insufficient (but has_sub_assemblies): (item.available_count / assembly.quantity) < @remainder && item.has_sub_assemblies?
      # 3. item_insufficient (and_has_no_sub_assemblies): (item.available_count / assemblies.quantity) < @remainder && !item.has_sub_assemblies?

      if @item.available_count >= to_remove
        item_can_satisfy_remainder(to_remove)
      else
        # creates a count that zeros out the @item.loose_count and @item.box_count
        item_insufficient

        # prepares for next level of tree traversal
        item_has_sub_assemblies if @item.has_sub_assemblies?
      end
    end
  end
end
