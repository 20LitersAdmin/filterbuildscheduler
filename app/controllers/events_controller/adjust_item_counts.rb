# frozen_string_literal: true

class EventsController
  class AdjustItemCounts
    def initialize(event, loose, box)
      @event                = event
      @loose_created        = loose
      @box_created          = box

      @technology                   = event.technology
      @current_loose_count          = @technology.loose
      @current_box_count            = @technology.box_count
      @technology_quantity_per_box  = @technology.quantity_per_box

      @inventory = @event.create_inventory(date: Date.today, completed_at: Time.now)

      @produced_and_boxed = (@box_created * @technology_quantity_per_box)
      @produced_total     = @produced_and_boxed + @loose_created

      # Strategies:
      # 1. Add @box to @technology.box_count
      add_box_to_box_count if @box_created.positive?

      # 2. box up @technology.loose_count into @technology.box_count
      #   - @technology.loose_count.divmod(@technology.quantity_per_box) => [div (boxes), mod (remaining)] trying to have div equal @box

      # at least one box can be created
      box_up_loose_technologies if @current_loose_count > @technology_quantity_per_box

      # 3. "assemble" direct nodes to create more technologies
      #   - decrement @remainder as more @technologies are "assembled"

      # Near the end: Add @loose to @technology.loose_count
      # second from the end: @technology.set_history_from_current_counts
      # End: @technology.save
    end
  end
end
