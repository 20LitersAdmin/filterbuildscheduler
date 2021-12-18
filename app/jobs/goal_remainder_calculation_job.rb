# frozen_string_literal: true

class GoalRemainderCalculationJob < ApplicationJob
  queue_as :goal_remainder

  def perform(technology = nil)
    ActiveRecord::Base.logger.level = 1

    puts '========================= Starting GoalRemainderCalculationJob ========================='

    # Job can be called with a specific technology to only change related items
    # or with no specific tech to change all items
    if technology.present?
      set_all_tech_items_goal_remainders_to_zero(technology)
      loop_technology(technology)
    else
      set_all_item_goal_remainders_to_zero

      Technology.with_set_goal.each do |tech|
        loop_technology(tech)
      end
    end

    puts '========================= Finished GoalRemainderCalculationJob ========================='

    ActiveRecord::Base.logger.level = 0
  end

  def loop_assemblies(combination, available)
    combination.assemblies.each do |assembly|
      item = assembly.item
      added_available = combination.available_count + available
      minus_remainder = -(added_available * assembly.quantity)

      # TODO: Here
      byebug if item.uid == 'C043'

      set_item_goal_remainder(item, minus_remainder)

      next unless item.has_sub_assemblies?

      loop_assemblies(item, added_available) if assembly.item_type == 'Component'

      set_material_goal_remainder(item, added_available) if assembly.item_type == 'Part'
    end
  end

  def loop_technology(tech)
    # Already have more than needed? leave every down-tree item with a goal_reaminder of 0 and move on
    return if tech.available_count >= tech.default_goal

    base_remainder = tech.default_goal - tech.available_count

    tech.quantities.each do |uid, quantity|
      # set all item goal_remainders based on quantity per technology,
      # ignoring related Component counts for the time being
      item = uid.objectify_uid

      set_item_goal_remainder(item, (base_remainder * quantity).ceil - item.available_count)
    end

    # Now start subtracting based on related Component available_counts
    # since we set all the item_goals with the base_remainder, we pass zero to the assemblies loop
    tech.assemblies.where(item_type: 'Component').each do |assembly|
      # TODO: Here
      loop_assemblies(assembly.combination, -base_remainder)
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

  def set_item_goal_remainder(item, new_remainder)
    remainder = [item.goal_remainder + new_remainder, 0].max
    item.update_columns(goal_remainder: remainder)
  end

  def set_material_goal_remainder(part, remainder)
    return unless part.quantity_from_material.positive?

    material = part.material
    remainder = [material.goal_remainder - (part.available_count / part.quantity_from_material), 0].max

    material.update_columns(goal_remainder: remainder)
  end
end
