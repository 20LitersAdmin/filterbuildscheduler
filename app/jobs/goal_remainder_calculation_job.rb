# frozen_string_literal: true

class GoalRemainderCalculationJob < ApplicationJob
  queue_as :goal_remainder

  def perform(*_args)
    ActiveRecord::Base.logger.level = 1

    puts '========================= Starting GoalRemainderCalculationJob ========================='

    set_all_item_goal_remainders_to_zero

    Technology.with_set_goal.each do |tech|
      remainder = [tech.default_goal - tech.available_count, 0].max

      loop_assemblies(tech, remainder) unless remainder.zero?
    end

    puts '========================= Finished GoalRemainderCalculationJob ========================='

    ActiveRecord::Base.logger.level = 0
  end

  def loop_assemblies(combination, remainder)
    combination.assemblies.each do |assembly|
      item = assembly.item
      new_remainder = [(assembly.quantity * remainder) - item.available_count, 0].max

      set_item_goal_remainder(item, new_remainder) if new_remainder.positive?

      next unless item.has_sub_assemblies?

      loop_assemblies(item, new_remainder) if assembly.item_type == 'Component'

      set_material_goal_remainder(item, new_remainder) if assembly.item_type == 'Part'
    end
  end

  def set_all_item_goal_remainders_to_zero
    [Component, Part, Material].each do |item_class|
      item_class.update_all goal_remainder: 0
    end
  end

  def set_item_goal_remainder(item, new_remainder)
    item.update_columns(goal_remainder: item.goal_remainder + new_remainder)
  end

  def set_material_goal_remainder(part, remainder)
    material = part.material
    new_remainder = [(remainder / part.quantity_from_material).ceil - material.available_count, 0].max

    return if new_remainder.zero?

    material.update_columns(goal_remainder: material.goal_remainder + new_remainder)
  end
end
