# frozen_string_literal: true

class CountTransferJob < ApplicationJob
  queue_as :count_transfer

  attr_accessor :inventory, :receiving

  # called by InventoriesController#update via @inventory.run_count_transfer_job

  def perform(inventory)
    return if inventory.blank?

    @inventory = inventory
    @receiving = @inventory.receiving?

    if @inventory.manual?
      @inventory.counts.submitted.each do |count|
        transfer_manual_count(count)
      end
    else
      # event_based only creates counts for necessary items, so all should be transfered
      # non-event_based create all counts, so only transfer those that were submitted
      counts = @inventory.event_based? ? @inventory.counts : @inventory.counts.submitted
      counts.each do |count|
        transfer_auto_count(count)
      end
    end

    # save the history, which is populated by the #transfer_ methods
    @inventory.save

    @inventory.counts.destroy_all
  end

  def transfer_auto_count(count)
    # shipping, receiving and event inventories need to combine their counts with current item counts
    item = count.item

    item.loose_count += count.loose_count
    item.box_count += count.unopened_boxes_count
    item.available_count += count.available

    # Counts for Shipping, Receiving and Event inventories only show the change, not the new _count values, which makes the item's history series incorrect.
    item.history[@inventory.date.iso8601] = item.history_hash_for_self(@inventory.type)

    if @receiving
      item.last_received_at = Time.now.localtime
      item.last_received_quantity = count.available
    end

    item.save
    @inventory.history[item.uid] = count.history_hash_for_inventory
  end

  def transfer_manual_count(count)
    # manual inventories override current item counts
    item = count.item

    item.loose_count = count.loose_count
    item.box_count = count.unopened_boxes_count
    item.available_count = count.available

    # using the count values to cast into the Inventory history JSON saves is possible here because the count values override the item's counts.
    item.history[@inventory.date.iso8601] = count.history_hash_for_item
    item.save

    @inventory.history[item.uid] = count.history_hash_for_inventory
  end
end
