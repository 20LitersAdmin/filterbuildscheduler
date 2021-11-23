# frozen_string_literal: true

class CountCreateJob < ApplicationJob
  queue_as :count_create

  attr_accessor :inventory

  # called by InventoriesController#create with #perform_now

  def perform(inventory, technologies_params = [])
    @inventory = inventory

    tech_uids_to_skip = technologies_params.present? ? technologies_params['technologies'] : []

    item_uids = []

    techs = Technology.list_worthy.where.not(uid: tech_uids_to_skip)

    return unless techs&.any?

    techs.each do |technology|
      item_uids << technology.uid
      item_uids << technology.quantities.keys
    end

    item_uids.flatten.uniq.each do |item_uid|
      create_count(item_uid.objectify_uid)
    end
  end

  def create_count(item)
    # String.objectify_uid returns nil if nothing is found
    return if item.nil?

    Count.create(
      inventory_id: @inventory.id,
      item: item,
      loose_count: 0,
      unopened_boxes_count: 0
    )
  end
end
