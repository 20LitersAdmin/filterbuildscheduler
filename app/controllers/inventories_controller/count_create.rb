class InventoriesController
  class CountCreate
    def initialize(inventory)
      @inventory = inventory
      @latest = Inventory.former.first
      if @latest.present?
        @latest_id = @latest.id
      else
        @latest_id = nil
      end

      ### Make all the parts
      @part_ids = Part.all.map { |o| o.id }
      @part_ids.each do |p|
        old_part_count = Count.where(inventory_id: @latest_id).where(part_id: p).last
        if old_part_count.present?
          new_part_count = old_part_count.dup
          new_part_count.inventory_id = @inventory.id
          new_part_count.user_id = nil
          new_part_count.extrapolated_count = 0
          new_part_count.save
        else
          Count.create(inventory_id: @inventory.id, part_id: p)
        end
      end

      @material_ids = Material.all.map { |o| o.id }
      @material_ids.each do |m|
        old_material_count = Count.where(inventory_id: @latest_id).where(material_id: m).last
        if old_material_count.present?
          new_material_count = old_material_count.dup
          new_material_count.inventory_id = @inventory.id
          new_material_count.user_id = nil
          new_material_count.extrapolated_count = 0
          new_material_count.save
        else
          Count.create(inventory_id: @inventory.id, material_id: m)
        end
      end

      @component_ids = Component.all.map { |o| o.id }
      @component_ids.each do |c|
        old_component_count = Count.where(inventory_id: @latest_id).where(component_id: c).last
        if old_component_count.present?
          new_component_count = old_component_count.dup
          new_component_count.inventory_id = @inventory.id
          new_component_count.user_id = nil
          new_component_count.extrapolated_count = 0
          new_component_count.save
        else
          Count.create(inventory_id: @inventory.id, component_id: c)
        end
      end

    end
  end
end
