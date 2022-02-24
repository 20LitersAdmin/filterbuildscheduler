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
      process_technology

      @technology.reload.quantities.each do |k, v|
        insert_into_item_quantities(k, v)
      end
    end

    puts '========================= FINISHED QuantityAndDepthCalculationJob ========================='

    ActiveRecord::Base.logger.level = 0
  end

  def process_technology
    # clear out any historical quantities
    @technology.quantities = {}

    # this array gets populated via the assemblies_loop
    @part_ids_made_from_material = []

    # this counter is used to set the Assembly#depth needed for accurate PriceCalculationJob results
    @counter = 0
    assemblies_loop(@technology.assemblies)

    loop_parts_for_materials if @part_ids_made_from_material.any?

    @technology.save
  end

  def assemblies_loop(assemblies, parent_quantity = 1)
    # reset the hash to avoid infinite looping
    components_hash = {}

    puts "Starting assemblies loop for #{@technology.name}"
    assemblies.each do |a|
      # only set the depth to the counter if it's bigger than the existing value
      # this ensures that components or parts shared by multiple assemblies only
      # get pushed lower (via a bigger number) and not accidentally raised higher (via a smaller number)
      a.update_columns(depth: @counter) if @counter > a.depth

      new_quantity = parent_quantity * a.quantity

      insert_into_quantity(a.item.uid, new_quantity)

      components_hash[a.item_id] = new_quantity if a.item_type == 'Component'

      @part_ids_made_from_material << a.item_id if a.item_type == 'Part' && a.item&.made_from_material?
    end

    loop_components(components_hash) if components_hash.any?
  end

  def insert_into_quantity(uid, quantity)
    if @technology.quantities[uid].present?
      @technology.quantities[uid] += quantity
    else
      @technology.quantities[uid] = quantity
    end
  end

  def insert_into_item_quantities(uid, value)
    item = uid.objectify_uid

    # safety in case uid is somehow not in parity with id
    return unless item.present?

    item.quantities[@technology.uid] = value
    item.save
  end

  def loop_components(components_hash)
    puts "Starting loop_components for #{@technology.name}"
    components = Component.where(id: components_hash.keys)
    @counter += 1

    components.each do |c|
      assemblies_loop(c.sub_assemblies, components_hash[c.id])
    end

    @counter -= 1
  end

  def loop_parts_for_materials
    Part.where(id: @part_ids_made_from_material.uniq).each do |part|
      next unless part.quantity_from_material.positive?

      # technology.quantities[part.uid] will already exist
      # because assemblies_loop gathers part ids into @part_ids_made_from_material
      # which is then accessed here
      parts_per_technology = @technology.quantities[part.uid]

      # ensure this floats as parts_per_technology is usually < part.quantity_from_material
      material_per_technology = parts_per_technology / part.quantity_from_material.to_f

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
