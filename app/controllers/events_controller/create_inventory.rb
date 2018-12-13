# frozen_string_literal: true

class EventsController
  class CreateInventory
    def initialize(event, loose, box, current_user_id)
      inventory = Inventory.where(event_id: event.id).first_or_initialize
      inventory.update(date: Date.today, completed_at: Time.now)

      if inventory.counts.count == 0
        InventoriesController::CountCreate.new(inventory)
      end

      if (loose + box) > 0
        # record the results of the event in the inventory
        CountPopulate.new(loose, box, event, inventory, current_user_id)
        
        # subtract the sub-components and parts related to the event's technology
        SubtractSubsets.new(loose, box, event, inventory)

        # extrapolate out the full inventory given the new results
        InventoriesController::Extrapolate.new(inventory)
      end

      inventory.reload
    end
  end
end