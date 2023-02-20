# frozen_string_literal: true

class GoalRemainderCalculationJob < ApplicationJob
  queue_as :goal_remainder

  # NOTE: This is v2 attempt

  # NOTE: This job is fired from:
  # Part#after_save when #quantity_from_material || #made_from_material is changed
  # Itemable#after_update
  # Assembly#after_save && #after_destroy
  # InventoriesController#update via @inventory.run_goal_remainder_calculation_job

  def perform
    ActiveRecord::Base.logger.level = 1

    puts '========================= Starting GoalRemainderCalculationJob ========================='

    # Set every active item's goal_remainder to 0
    [Component, Part, Material].each do |item_class|
      item_class.kept.update_all goal_remainder: 0
    end

    Technology.with_set_goal.each do |tech|
      tech_available_count = tech.available_count
      tech_former_goal_remainder = tech.goal_remainder
      tech_default_goal = tech.default_goal
      tech_name = tech.name

      if tech_available_count >= tech_default_goal
        tech.update_columns(goal_remainder: 0) if tech_former_goal_remainder.nonzero?

        puts "= #{tech_name} has already completed the goal =+=+="
        next
      end

      # Set the goal_remainder for the technology
      tech_goal_remainder = tech_default_goal - tech_available_count
      tech.update_columns(goal_remainder: tech_goal_remainder) unless tech_former_goal_remainder == tech_goal_remainder

      puts "= #{tech_name} needs #{tech_goal_remainder} =+=+="

      @sub_assembly_array_of_ids = []
      @part_from_material_array = []

      # Set the goal_remainder for each tech's assemblies.
      # Traversing horizontally before moving down vertically
      # by saving any sub-assemblies into an array
      tech.reload.assemblies.without_price_only.ascending.each do |assembly|
        increase_assembly_item_goal(assembly)
      end

      while @sub_assembly_array_of_ids.any?
        # have to keep respecting the depth of the assembly, by using .ascending
        # to ensure we don't try to call item.allocate! when the item's parent
        # hasn't had their goal_remainder already set
        assemblies = Assembly.where(id: @sub_assembly_array_of_ids).ascending
        assemblies.each do |assembly|
          increase_assembly_item_goal(assembly)
          # remove this assembly from the array
          @sub_assembly_array_of_ids.delete(assembly.id)
        end
      end

      while @part_from_material_array.any?
        @part_from_material_array.each do |part|
          increase_material_goal(part)
          # remove this part from the array
          @part_from_material_array.delete(part)
        end
      end
    end

    puts '========================= Finished GoalRemainderCalculationJob ========================='

    ActiveRecord::Base.logger.level = 0
  end

  def increase_assembly_item_goal(assembly)
    puts "#{assembly.depth} -- #{assembly.name_long}"
    item = assembly.item.reload

    combination = assembly.combination
    combination_uid = combination.uid
    combination_goal_remainder = combination.goal_remainder
    current_goal_remainder = item.goal_remainder

    new_goal_remainder = (combination_goal_remainder * assembly.quantity)

    # For items that are used by more than one assembly,
    # only allocate a weighted portion of the available_count.
    # This relies on traversing horizontally before moving vertically
    # to ensure that all parents of the item already have their goal remainder set
    item.allocate!
    item.reload
    weighted_available = (item.available_count * (item.allocations[combination_uid] || 1)).floor
    new_goal_remainder -= weighted_available

    item_goal_remainder = [new_goal_remainder, 0].max
    puts "=+= #{item.uid} #{item.name} has #{weighted_available} available, needs #{item_goal_remainder} to make #{combination_goal_remainder} #{combination_uid} #{combination.name} =+="

    # byebug if ['blue', 'red'].include? item.name

    # if item.name == "elbow"
    #   blue = item.allocations.keys.first.objectify_uid
    #   red = item.allocations.keys.second.objectify_uid
    #   byebug
    # end

    item_goal_remainder += current_goal_remainder

    item.update_columns(goal_remainder: item_goal_remainder) unless current_goal_remainder == item_goal_remainder

    return unless item.has_sub_assemblies?

    if item.is_a? Component
      # Ensure horizontal traversal by collecting all sub_assemblies
      @sub_assembly_array_of_ids << item.sub_assemblies.ascending.pluck(:id)
      @sub_assembly_array_of_ids.flatten!
    else # item is a Part made from Materials
      @part_from_material_array << item
    end
  end

  def increase_material_goal(part)
    material = part.reload.material
    current_goal_remainder = material.goal_remainder

    new_goal_remainder = (part.goal_remainder / part.quantity_from_material.to_f).ceil

    # For materials that make multiple parts,
    # only allocate a weighted portion of the available_count
    # This relies on traversing horizontally before moving vertically
    # to ensure that all parts made from the material already have their goal remainder set
    material.allocate!
    new_goal_remainder -= material.available_count * [material.allocations[part.uid], 1].without(nil).min
    material_goal_remainder = [new_goal_remainder, 0].max + current_goal_remainder

    material.update_columns(goal_remainder: material_goal_remainder) unless current_goal_remainder == material_goal_remainder
  end
end
