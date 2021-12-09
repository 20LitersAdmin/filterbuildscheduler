# frozen_string_literal: true

class QuantityAndDepthCalculationJob < ApplicationJob
  queue_as :quantity_calc

  attr_accessor :technology, :component_ids, :part_ids_made_from_material, :counter

  def perform(*_args)
    ActiveRecord::Base.logger.level = 1

    puts '========================= Starting QuantityAndDepthCalculationJob ========================='

    set_all_assembly_depths_to_zero
    set_all_item_quantities_to_zero

    Technology.list_worthy.each do |technology|
      @technology = technology
      loop_technology

      @technology.reload.quantities.each do |k, v|
        insert_into_item_quantities(k, v)
      end
    end

    puts '========================= FINISHED QuantityAndDepthCalculationJob ========================='

    ActiveRecord::Base.logger.level = 0
  end

  def loop_technology
    # clear out any past quantity history
    @technology.quantities = {}

    # these arrays get populated via the assemblies_loop
    @component_ids = []
    @part_ids_made_from_material = []

    # this counter is used to set the Assembly#depth needed for accurate PriceCalculationJob results
    @counter = 0
    assemblies_loop(@technology.assemblies)

    loop_parts_for_materials(@part_ids_made_from_material.uniq)

    @technology.save
  end

  def assemblies_loop(assemblies)
    assemblies.each do |a|
      # only set the depth to the counter if it's bigger than the existing value
      # this ensures that components or parts shared by multiple assemblies only
      # get pushed lower (via a bigger number) and not accidentally raised higher (via a smaller number)
      a.update_columns(depth: @counter) if @counter > a.depth
      insert_into_quantity(a)

      @component_ids << a.item_id if a.item_type == 'Component'

      @part_ids_made_from_material << a.item_id if a.item_type == 'Part' && a.item&.made_from_material?
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

  def insert_into_item_quantities(uid, value)
    item = uid.objectify_uid

    # safety in case uid is somehow not in parity with id
    return unless item.present?

    item.quantities[@technology.uid] = value
    item.save
  end

  def loop_components(component_ids)
    components = Component.where(id: component_ids)
    # reset the array to avoid infinite looping
    @component_ids = []
    @counter += 1

    components.each do |c|
      assemblies_loop(c.sub_assemblies)
    end

    @counter -= 1
  end

  def loop_parts_for_materials(part_ids)
    Part.where(id: part_ids).each do |part|
      next if part.quantity_from_material.zero?

      # technology.quantities[part.uid] will already exist
      # because assemblies_loop gathers part ids into @part_ids_made_from_material
      # which is then passed to here
      parts_per_technology = @technology.quantities[part.uid]

      material_per_technology = parts_per_technology / part.quantity_from_material

      if @technology.quantities[part.material.uid].present?
        @technology.quantities[part.material.uid] += material_per_technology
      else
        @technology.quantities[part.material.uid] = material_per_technology
      end
    end
  end

  def set_all_assembly_depths_to_zero
    Assembly.update_all depth: 0
  end

  def set_all_item_quantities_to_zero
    Component.update_all quantities: {}
    Part.update_all quantities: {}
    Material.update_all quantities: {}
  end
end
