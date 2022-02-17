# frozen_string_literal: true

class GoalRemainderCalculationJob < ApplicationJob
  queue_as :goal_remainder

  def perform(technology = nil)
    ActiveRecord::Base.logger.level = 1

    # even if the job is called with a specific technology, it must have a default goal to run
    return false if technology.present? && !technology.default_goal.positive?

    puts '========================= Starting GoalRemainderCalculationJob ========================='

    # Job can be called with a specific technology to only change related items
    # or with no specific tech to change all items
    if technology.present?
      set_all_tech_items_goal_remainders_to_zero(technology)

      process_technology(technology)
    else
      set_all_item_goal_remainders_to_zero

      Technology.with_set_goal.each do |tech|
        process_technology(tech)
      end
    end

    puts '========================= Finished GoalRemainderCalculationJob ========================='

    ActiveRecord::Base.logger.level = 0
  end

  def process_assembly(assembly, parent_available)
    item = assembly.item

    in_parent_available = parent_available * assembly.quantity
    new_goal_remainder = item.goal_remainder - in_parent_available

    ## assembly.affects_price_only?:
    # These items are not part of a complete unit until later on (e.g. buckets and lids are added to the shipping container, not stored with every complete SAM3)
    # so we need to add back the combination.available_count * assembly.quantity
    new_goal_remainder += (assembly.combination.available_count * assembly.quantity) if assembly.affects_price_only?

    item.update_columns(goal_remainder: [new_goal_remainder, 0].max)

    return unless item.has_sub_assemblies?

    if assembly.item_type == 'Part'
      # Parts made from materials
      material = item.material

      # keeping both numbers as integers under-values how many materials
      # are in parent items, which keeps the number in goal_remainder rounded up,
      # providing overage.
      material_in_parent_available = (item.available_count + in_parent_available) / item.quantity_from_material

      material_new_goal_remainder = material.goal_remainder - material_in_parent_available

      material.update_columns(goal_remainder: [material_new_goal_remainder, 0].max)
    else
      # Components with sub_assemblies
      combined_available = item.available_count + in_parent_available

      item.assemblies.without_price_only.each do |sub_assembly|
        process_assembly(sub_assembly, combined_available)
      end
    end
  end

  def process_technology(tech)
    # Already have more than needed? leave every down-tree item with a goal_reaminder of 0 and move on
    if tech.available_count >= tech.default_goal
      puts "=+= #{tech.name} has already completed the goal =+="
      return
    end

    puts "=+= processing for #{tech.name} =+="

    tech.update_columns(goal_remainder: tech.default_goal - tech.available_count)

    remaining_need = tech.reload.goal_remainder

    tech.quantities.each do |uid, quantity|
      # set all item goal_remainders based on quantity per technology,
      # ignoring the available count of any parents for the moment
      item = uid.objectify_uid

      # for items that are used in multiple technologies, increase the goal_remainder instead of overwriting it
      if item.goal_remainder.zero?
        item.update_columns(goal_remainder: (remaining_need * quantity).ceil - item.available_count)
      else
        # don't subtract the available_count as this was done the first time, when item.goal_remainder == 0
        item.update_columns(goal_remainder: item.goal_remainder + (remaining_need * quantity))
      end
    end

    tech.assemblies.each do |assembly|
      # since all items' goal_remainders are already set to the max remaining_need, pass 0 available here
      process_assembly(assembly, 0)
    end
  end

  def set_all_item_goal_remainders_to_zero
    [Component, Part, Material].each do |item_class|
      item_class.update_all goal_remainder: 0
    end
  end

  def set_all_tech_items_goal_remainders_to_zero(tech)
    tech.quantities.each_key do |item_uid|
      item_uid.objectify_uid.update_columns(goal_remainder: 0)
    end
  end
end
