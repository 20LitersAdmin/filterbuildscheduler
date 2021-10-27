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

    technology_has_sufficient_loose_count = @technology.loose_count > @produced_and_boxed

    # Option 1: There were enough existing @technology loose items, they were just boxed, nothing had to be produced

    create_technology_count_only if technology_has_sufficient_loose_count
    # sloppy early return
    return true if technology_has_sufficient_loose_count

    # @technology couldn't handle it alone, time to rely on the tree
    set_remainder_and_technology

    # @remainder is set and represents what we still need to "produce" from sub items

    # when assembly.item is a Component, put it here for the next iteration of the loop
    @component_ids = []
    @part_ids_made_from_material = []

    loop_assemblies(@technology)

    # run @inventory.update to trigger CountTransfer job:
    @inventory.update(completed_at: Time.now)
  end

  def create_count(item, loose_count, box_count)
    # KEEP IN MIND: the count values should not be the new values, but instead the amount to add or subtract from the item
    # see CountTransferJob#transfer_auto_count

    @inventory.counts.create(
      item: item,
      loose_count: loose_count,
      unopened_boxes_count: box_count
    )
  end

  def create_technology_count_only
    # we assume that the @event.boxes_packed are all new and added to the existing total
    #   @technology.box_count += @box_created
    # we assume that previous @technology.loose_count were used to achieve @box_created and any remainder are added with what loose items were produced
    #   @technology.loose_count = (@technology.loose_count - @produced_and_boxed) + @loose_created

    new_loose_count = @technology.loose_count - @produced_and_boxed + @loose_created
    create_count(@technology, new_loose_count, @box_created)
  end

  def loop_assemblies(combination)
    # Use a collection to step down one level, then across the tree (across first, down second)
    # instead of just looping inside a loop, which traverses down all the way first (down first, across second)

    assemblies = Assembly.where(combination: combination)

    assemblies.each do |assembly|
      item = assembly.item

      # TODO: HERE
      # Three options:
      # 1. item_can_satisfy_remainder: (item.available_count / assembly.quantity) >= @remainder
      #   a. (item.loose_count / assembly.quantity) >= @remainder
      #     - create_count(item, -(@remainder * assembly.quantity), 0)
      #
      #   b. (item.loose_count / assembly.quantity) < @remainder
      #     - calculate number of boxes that need to be opened
      #     - calculate new loose_count (after "opening" boxes), will be [plus the opened boxes quantity, minus the (@remainder * assembly.quantity)]
      #     - create_count(item, new_loose_count, number_of_boxes_opened_as_negative)
      #
      # 2. item_insufficient_but_has_sub_assemblies: (item.available_count / assembly.quantity) < @remainder && item.has_sub_assemblies?
      # Save the IDs for future traversal across
      # @component_ids << assembly.item_id if assembly.item_type == 'Component'

      # @part_ids_made_from_material << assembly.item_id if assembly.item_type == 'Part' && item.made_from_material?

      # 3. item_insufficient_and_has_no_sub_assemblies: (item.available_count / assemblies.quantity) < @remainder && !item.has_sub_assemblies?
    end
  end

  def set_remainder_and_technology
    # we assume that previous @technology.loose_count were used towards @produced_and_boxed, but were insufficient to fully satisfy @produced_and_boxed, bringing @technology.loose_count to 0 and leaving us with a remainder
    @remainder = @produced_and_boxed - @technology.loose_count

    # we assume that the @event.technologies_built is now the new value for @technology.loose_count

    create_count(@technology, @loose_created, @box_created)
  end
end
