# frozen_string_literal: true

class InventoriesController
  class CountCreate
    def initialize(inventory, technologies_params = [])
      @inventory = inventory

      @tech_uids_to_skip = technologies_params.present? ? technologies_params['technologies'] : []

      item_uids = []

      Technology.where.not(uid: @tech_uids_to_skip).each do |technology|
        item_uids << technology.uid
        item_uids << technology.quantities.keys
      end

      item_uids.flatten.uniq.each do |item_uid|
        create_count(item_uid.objectify_uid)
      end
    end

    def create_count(item)
      # TODO: start with blank counts?
      Count.create(
        inventory_id: @inventory.id,
        item: item,
        loose_count: 0,
        unopened_boxes_count: 0
      )
    end
  end
end
