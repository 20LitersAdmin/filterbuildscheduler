# frozen_string_literal: true

class ProduceableJob < ApplicationJob
  queue_as :produceable

  def perform(*_args)
    ActiveRecord::Base.logger.level = 1

    puts '========================= Starting ProduceableJob ========================='

    # Definition: can_be_produced is the smallest of the available count of all children * quantity of children needed per parent

    # item.available_count + item.can_be_produced indicates how many combination.can_be_prodced.

    puts 'set :can_be_produced to nil for all Components, and Technologies'
    # this way I can check for un-touched records
    Component.update_all(can_be_produced: nil)
    Technology.update_all(can_be_produced: nil)

    # start with materials as they are always the bottom of the list
    # Materials can go up because parts only rely on one material

    puts 'loop over all materials to set their parts\' produceable value'
    Material.kept.with_parts.each do |m|
      m.parts.each do |pa|
        # multiplication here because one material always makes one or more parts
        produceable = (m.available_count * pa.quantity_from_material)

        # skip callbacks for speed and to avoid triggering another job
        pa.update_columns(can_be_produced: produceable)
      end
    end

    # make sure parts that aren't made from materials have their produceable amount set
    puts 'set remaining part\'s produceable value to 0'
    Part.kept.not_made_from_material.update_all(can_be_produced: 0)

    # TODO: ideal way:
    # Component.with_only_parts

    # Assembly.part_items + Assembly.component_items == Assembly.all

    puts 'loop over all Assembly.part_items'
    Assembly.part_items.each do |a|
      calculate_for_combination(a)
    end

    puts 'loop over all Assembly.component_items'
    Assembly.component_items.each do |a|
      calculate_for_combination(a)
    end

    puts '========================= FINISHED ProduceableJob ========================='

    ActiveRecord::Base.logger.level = 0
  end

  def calculate_for_combination(assembly)
    combination = assembly.combination
    current_produceable = combination.can_be_produced
    item = assembly.item

    # division here because one or more item is always needed to make one combination
    produceable = (item.can_be_produced + item.available_count) / assembly.quantity
    # NOTE: the above carries the :can_be_produced up from the bottom of the tree, whic always assumes all sub-items will be allocated to this combination, and will over-estimate what can actually be produced.

    # the alternative is to do something like item.super_assemblies.pluck(:quantity).sum to get the total number needed across all assemblies and use that to allocate the item evenly, which will under-estimate what can be produced as it assumes that all assemblies must be produced equally regardless of combination or technology.

    # when current_produceable == nil: it hasn't been set yet
    # when current_produceable > produceable: it should be lowered
    # this ensures that can_be_produced is set to the minimum of child assemblies
    combination.update_columns(can_be_produced: produceable) if current_produceable.nil? || current_produceable > produceable
  end
end
