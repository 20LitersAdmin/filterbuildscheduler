# frozen_string_literal: true

class CountTransferJob < ApplicationJob
  queue_as :count_transfer

  # called by Inventory#after_update callback

  def perform(inventory)
    @inventory = inventory
    @receiving = @inventory.receiving?

    if @inventory.manual?
      @inventory.counts.changed.each do |count|
        transfer_manual_count(count)
      end
    else
      counts = @inventory.event_based? ? @inventory.counts : @inventory.counts.changed
      counts.each do |count|
        transfer_auto_count(count)
      end
    end

    # save the history
    @inventory.save

    @inventory.counts.destroy_all
  end

  def transfer_manual_count(count)
    # manual inventories override current item counts
    item = count.item

    return false unless item.present?

    item.loose_count = count.loose_count
    item.box_count = count.unopened_boxes_count
    item.available_count = count.available
    item.history[@inventory.date.iso8601] = count.history_hash_for_item
    item.save

    @inventory.history[item.uid] = count.history_hash_for_inventory
  end

  def transfer_auto_count(count)
    # shipping, receiving and event inventories need to combine their counts with current item counts
    item = count.item

    return false unless item.present?

    item.loose_count += count.loose_count
    item.box_count += count.unopened_boxes_count
    item.available_count += count.available

    item.history[@inventory.date.iso8601] = count.history_hash_for_item

    if @receiving
      item.last_received_at = Time.now.localtime
      item.last_received_quantity = count.available
    end

    item.save

    @inventory.history[item.uid] = count.history_hash_for_inventory
  end
end
