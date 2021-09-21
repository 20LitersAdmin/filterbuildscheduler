# frozen_string_literal: true

class QuantityAndDepthCalculationJob < ApplicationJob
  queue_as :quantity_calc

  def perform(*_args)
    ActiveRecord::Base.logger.level = 1

    set_all_assembly_depths_to_zero
    set_all_item_quantities_to_zero

    Technology.list_worthy.each do |technology|
      @technology = technology
      puts "========================= Starting #{@technology.name} ========================="
      loop_technology

      puts 'Setting Item quantities on items'
      @technology.reload.quantities.each do |k, v|
        insert_into_item_quantities(k, v) unless k[0] == 'C'
      end

      puts "========================= FINISHED #{@technology.name} ========================="
    end

    ActiveRecord::Base.logger.level = 0
  end

  def loop_technology
    # clear out any past quantity history
    @technology.quantities = {}

    # these arrays get populated via the assemblies_loop
    @component_ids = []
    @part_ids_made_from_materials = []

    # this counter is used to set the Assembly#depth needed for accurate PriceCalculationJob results
    @counter = 0
    puts "Counter is set to #{@counter} for component_items"
    assemblies_loop(@technology.assemblies)

    loop_parts_for_materials(@part_ids_made_from_materials.uniq)

    @technology.save
  end

  def assemblies_loop(assemblies)
    puts '(starting an assembly loop)'
    assemblies.each do |a|
      puts "Counter is at #{@counter} for #{a.types} => #{a.combination.name}:#{a.item.name}"
      if @counter > a.depth
        puts "Assembly depth was at #{a.depth}"
      else
        puts "Assembly depth is at #{a.depth}"
      end
      # only set the depth to the counter if it's higher than the existing value
      # this ensures that components or parts shared by multiple assemblies only
      # get pushed lower and not accidentally raised higher
      a.update_columns(depth: @counter) if @counter > a.depth
      puts "Assembly depth is now at #{a.depth}" if @counter > a.depth

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

  def insert_into_item_quantities(key, value)
    item = key.objectify_uid
    item.quantities[@technology.uid] = value
    item.save
  end

  def loop_components(component_ids)
    components = Component.where(id: component_ids)
    # reset the array to avoid infinite looping
    @component_ids = []
    @counter += 1
    puts "Counter is incremented to #{@counter}"

    puts '(starting a component loop)'
    components.each do |c|
      assemblies_loop(c.sub_assemblies)
    end
    puts '(ending a component loop)'

    @counter -= 1
    puts "Counter is decremented to #{@counter}"
  end

  def loop_parts_for_materials(part_ids)
    Part.where(id: part_ids).each do |part|
      parts_per_technology = @technology.quantities[part.uid]

      next if part.quantity_from_material.zero?

      materials_per_technology = parts_per_technology / part.quantity_from_material

      if @technology.quantities[part.material.uid].present?
        @technology.quantities[part.material.uid] += materials_per_technology
      else
        @technology.quantities[part.material.uid] = materials_per_technology
      end
    end
  end

  def set_all_assembly_depths_to_zero
    Assembly.update_all(depth: 0)
  end

  def set_all_item_quantities_to_zero
    Part.update_all(quantities: {})
    Material.update_all(quantities: {})
  end
end
