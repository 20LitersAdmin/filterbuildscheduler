# frozen_string_literal: true

class InventoriesController
  class CountTransfer
    def initialize(inventory)
      @inventory = inventory
      @receiving = @inventory.receiving?

      if @inventory.manual?
        @inventory.counts.changed.each do |count|
          transfer_manual_count(count)
        end
      else
        @inventory.counts.changed.each do |count|
          transfer_auto_count(count)
        end
      end

      @inventory.counts.destroy_all
    end

    def transfer_manual_count(count)
      # manual inventories override current item counts
      item = count.item
      item.loose_count = count.loose_count
      item.box_count = count.unopened_boxes_count
      item.available_count = count.available
      item.set_history_from_curent_counts @inventory.date
      item.save
    end

    def transfer_auto_count(count)
      # shipping, receiving and event inventories need to combine their counts with current item counts
      item = count.item

      # coerce nils to 0 if necessary
      item.loose_count += count.loose_count
      item.box_count += count.unopened_boxes_count
      item.available_count += count.available

      item.history[@inventory.date.iso8601] = { loose: count.loose_count, box: count.unopened_boxes_count, available: count.available }

      item.save

      return unless @receiving

      item.last_received_at = Time.now.localtime
      item.last_received_quantity = count.available
    end
  end
end
