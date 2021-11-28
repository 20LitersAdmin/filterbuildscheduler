# frozen_string_literal: true

class CountCreateJob < ApplicationJob
  queue_as :count_create

  attr_accessor :inventory

  # called by InventoriesController#create with #perform_now

  def perform(inventory, technologies_params = { 'technologies': [] })
    @inventory = inventory

    tech_uids_to_skip = technologies_params['technologies'].presence

    if tech_uids_to_skip
      item_uids_to_potentially_skip = Technology.active
                                                .where(uid: tech_uids_to_skip)
                                                .map { |t| t.quantities.keys }
                                                .flatten.uniq.sort

      techs = Technology.list_worthy.where.not(uid: tech_uids_to_skip)

      item_uids_to_not_skip = techs.list_worthy
                                   .where.not(uid: tech_uids_to_skip)
                                   .map { |t| t.quantities.keys }
                                   .flatten.uniq.sort

      item_uids_to_definitely_skip = (item_uids_to_potentially_skip - item_uids_to_not_skip).sort
    else
      techs = Technology.list_worthy
      item_uids_to_definitely_skip = []
    end

    items = []
    items << techs
    items << Component.active
    items << Part.active
    items << Material.active

    items.flatten(1).each do |item|
      next if item_uids_to_definitely_skip.include?(item.uid)

      create_count(item)
    end
  end

  def create_count(item)
    Count.create(
      inventory_id: @inventory.id,
      item: item,
      loose_count: 0,
      unopened_boxes_count: 0
    )
  end
end
