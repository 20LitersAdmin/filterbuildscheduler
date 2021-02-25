# frozen_string_literal: true

class InventoriesController
  class Receive
    def initialize(inventory)
      @inventory = inventory
      return unless @inventory.receiving?

      counts = @inventory.counts.changed.not_components

      counts.each do |c|
        prev = c.previous_count
        c.item.tap do |item|
          prev_available = prev.nil? ? 0 : prev.available

          item.last_received_at = Time.now.localtime
          item.last_received_quantity = c.available - prev_available
        end
      end
    end
  end
end
