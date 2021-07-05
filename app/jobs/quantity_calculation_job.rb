# frozen_string_literal: true

class QuantityCalculationJob < ApplicationJob
  queue_as :quantity_calc

  def perform(*_args)
    Technology.list_worthy.each do |technology|
      loop_technology(technology)
    end
  end

  def loop_technology(technology)
    @technology = technology
    @technology.quantities = {}

    @component_ids = []
    @part_ids_made_from_materials = []
    assemblies_loop(@technology.assemblies)

    loop_parts_for_materials(@part_ids_made_from_materials.uniq)

    @technology.save
  end

  def assemblies_loop(assemblies)
    assemblies.each do |a|
      insert_into_quantity(a)
      @component_ids << a.item_id if a.item_type == 'Component'
      @part_ids_made_from_materials << a.item_id if a.item_type == 'Part' && a.item&.made_from_materials?
    end

    loop_components(@component_ids) if @component_ids.any?
  end

  def insert_into_quantity(assembly)
    if @technology.quantities[assembly.item.uid].present?
      @technology.quantities[assembly.item.uid] += assembly.quantity
    else
      @technology.quantities[assembly.item.uid] = assembly.quantity
    end
  end

  def loop_components(component_ids)
    components = Component.where(id: component_ids)
    # reset the array to avoid infinite looping
    @component_ids = []
    components.each do |c|
      assemblies_loop(c.subassemblies) if c.subassemblies.any?
    end
  end

  def loop_parts_for_materials(part_ids)
    Part.where(id: part_ids).each do |part|
      parts_per_technology = @technology.quantities[part.uid]
      materials_per_technology = parts_per_technology / part.quantity_from_material

      if @technology.quantities[part.material.uid].present?
        @technology.quantities[part.material.uid] += materials_per_technology
      else
        @technology.quantities[part.material.uid] = materials_per_technology
      end
    end
  end
end
