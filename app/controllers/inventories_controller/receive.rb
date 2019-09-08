# frozen_string_literal: true

class InventoriesController
  class Receive
    def initialize(inventory)
      @inventory = inventory
      return unless @inventory.receiving?

      @counts = @inventory.counts.changed.not_components

      @counts.each do |c|
        prev = c.previous_count
        c.item.tap do |i|
          i.last_received_at = Time.now.localtime
          i.last_received_quantity = c.available - prev.available
          i.save
        end
      end
    end
  end
end
