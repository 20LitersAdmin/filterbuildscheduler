# frozen_string_literal: true

class CountCreateJob < ApplicationJob
  queue_as :count_create

  attr_accessor :inventory

  # called by InventoriesController#create with #perform_now

  def perform(inventory)
    return if inventory.blank?

    ActiveRecord::Base.logger.level = 1

    puts '========================= Starting CountCreateJob ========================='

    @inventory = inventory

    techs = Technology.active.where(id: inventory.technologies)

    items = []
    items << techs

    techs.each do |tech|
      # for Extrapolate inventories, only create counts for Technologies and Components
      items << tech.all_components
      items << tech.all_parts unless @inventory.extrapolate?
      items << tech.materials unless @inventory.extrapolate?
    end

    items.flatten(1).uniq.each do |item|
      create_count(item)
    end

    puts '========================= FINISHED CountCreateJob ========================='

    ActiveRecord::Base.logger.level = 0
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
