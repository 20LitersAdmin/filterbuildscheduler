# frozen_string_literal: true

class ProduceableJob < ApplicationJob
  queue_as :produceable

  # NOTE: This job is fired from:
  # InventoriesController#update via @inventory.run_produceable_job
  # Itemable#after_update
  # Assembly#after_save && #after_destroy
  # Part#after_save when #quantity_from_material || #made_from_material is chagned

  def perform
    ActiveRecord::Base.logger.level = 1

    puts '========================= Starting ProduceableJob ========================='

    # Definition: can_be_produced is the smallest of the available_count * quantity needed per parent of all children

    # item.available_count + item.can_be_produced indicates how many combination.can_be_prodced.

    # this way I can check for un-touched records
    Component.kept.update_all(can_be_produced: nil)
    Technology.kept.update_all(can_be_produced: nil)

    # start with materials as they are always the bottom of the list
    # Materials can go up because parts only rely on one material
    Material.kept.with_parts.each do |material|
      loop_parts(material)
    end

    # make sure parts that aren't made from materials have their produceable amount set
    Part.kept.not_made_from_material.update_all(can_be_produced: 0)

    # Assembly.part_items + Assembly.component_items == Assembly.all

    # Assembly.part_items are naturally lower nodes
    Assembly.without_price_only.part_items.each do |a|
      calculate_for_combination(a)
    end

    # Assembly.component_items are naturally higher nodes
    Assembly.without_price_only.component_items.each do |a|
      calculate_for_combination(a)
    end

    Component.kept.where(can_be_produced: nil).update_all(can_be_produced: 0)
    Technology.kept.where(can_be_produced: nil).update_all(can_be_produced: 0)

    puts '========================= FINISHED ProduceableJob ========================='

    ActiveRecord::Base.logger.level = 0
  end

  def calculate_for_combination(assembly)
    combination = assembly.combination
    current_produceable = combination.can_be_produced
    item = assembly.item

    # division here because one or more item(s) is always needed to make one combination
    produceable = (item.can_be_produced + item.available_count) / assembly.quantity
    # NOTE: the above carries the :can_be_produced up from the bottom of the tree, which always assumes all sub-items will be allocated to this combination, and will *over-estimate* what can actually be produced.

    # when current_produceable == nil: it hasn't been set yet
    # when current_produceable > produceable: it should be lowered
    # this ensures that can_be_produced is set to the minimum of child assemblies, which somewhat course-corrects for the over-estimation above
    combination.update_columns(can_be_produced: produceable) if current_produceable.nil? || current_produceable > produceable
  end

  def loop_parts(material)
    material.parts.each do |pa|
      update_part(pa, material.available_count)
    end
  end

  def update_part(part, material_available_count)
    # multiplication here because one material always makes one or more parts
    produceable = (material_available_count * part.quantity_from_material).floor

    # skip callbacks for speed and to avoid triggering another job
    part.update_columns(can_be_produced: produceable)
  end
end
