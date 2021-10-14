# frozen_string_literal: true

class EventInventoryJob < ApplicationJob
  queue_as :event_inventory

  def perform(event)
    # This job is auto-initialized by ProduceableJob.perform_*(event: event)
    @event          = event
    @loose_created  = @event.technologies_built
    @box_created    = @event.boxes_packed
    @technology     = event.technology

    @produced_and_boxed = (@box_created * @technology_quantity_per_box)
    @produced_total     = @produced_and_boxed + @loose_created

    @inventory = @event.create_inventory(date: Date.today, completed_at: Time.now)

    technology_has_sufficient_loose_count = @technology.loose_count > @produced_and_boxed

    # There were enough existing @technology loose items, they were just boxed, nothing had to be produced

    create_technology_count_only if technology_has_sufficient_loose_count
    # sloppy early return
    return true if technology_has_sufficient_loose_count

    # @technology couldn't handle it alone, time to rely on the tree
    set_remainder_and_technology

    # POINT OF ORDER: @technology.can_be_produced should be a legitimate indicator of success. :can_be_produced is combined with :available_count up from the bottom of the tree, which will *over-estimate* what can actually be produced, but represents the greatest possible value overall.

    # If @technology.can_be_produced < @remainder, we're sorta screwed and might as well not try...?

    # TODO: HERE: time to step on down the tree for a bit

    # Use a collection to step down then across the tree (across then down)
    # instead of just looping inside a loop, which traverses down all the way first (down then across)

    # when assembly.item is a Component, put it here for the next iteration of the loop
    @components = []

    loop_assemblies(@technology)
  end

  def create_count(item, loose_count, box_count)
    @inventory.counts.create(
      item: item,
      loose_count: loose_count,
      unopened_boxes_count: box_count
    )
  end

  def create_technology_count_only
    # the @technology count is unique because:
    # we assume that the @event.boxes_packed are all new and added to the existing total
    #   @technology.box_count += @box_created
    # we assume that previous @technology.loose_count were used to achieve @box_created and any remainder are added with what loose items were produced
    #   @technology.loose_count = (@technology.loose_count - @produced_and_boxed) + @loose_created

    new_loose_count = @technology.loose_count - @produced_and_boxed + @loose_created
    create_count(@technology, new_loose_count, @box_created)
  end

  def loop_assemblies(combination)
    # We have access to item.available_count + item.can_be_produced
  end

  def set_remainder_and_technology
    # we assume that previous @technology.loose_count were used towards @produced_and_boxed, but were insufficient to fully satisfy @produced_and_boxed, bringing @technology.loose_count to 0 and leaving us with a remainder
    @remainder = @produced_and_boxed - @technology.loose_count

    # we assume that the @event.technologies_built is now the new value for @technology.loose_count

    create_count(@technology, @loose_created, @box_created)
  end

  private

  def after_perform
    CountTransferJob.perform_later(@inventory)
  end
end
