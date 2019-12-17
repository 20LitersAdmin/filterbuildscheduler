# frozen_string_literal: true

class InventoriesController
  class CountCreate
    def initialize(inventory, technology_params, user)
      @inventory = inventory
      # Is there a previous inventory?
      @latest = Inventory.former.first
      @latest_id = @latest.present? ? @latest.id : nil

      @tech_ids = technology_params.present? ? technology_params['technologies'].map(&:to_i) : []
      @user_id = user.id

      make_parts
      make_materials
      make_components
    end

    def make_parts
      ### Make all the parts, use the previous Inventory's values if present.
      @part_ids = Part.all.pluck(:id)
      @part_ids.each do |pt|
        old_part_count = Count.where(inventory_id: @latest_id).where(part_id: pt).last
        part_count = old_part_count.present? ? duplicate(old_part_count) : create_part(pt)

        if @tech_ids.any?
          bypass(part_count) if @tech_ids.include?(part_count.technology&.id)
        end
      end
    end

    def make_materials
      ### Make all the materials, use the previous Inventory's values if present.
      @material_ids = Material.all.pluck(:id)
      @material_ids.each do |m|
        old_material_count = Count.where(inventory_id: @latest_id).where(material_id: m).last
        material_count = old_material_count.present? ? duplicate(old_material_count) : create_material(m)

        if @tech_ids.any?
          bypass(material_count) if @tech_ids.include?(material_count.technology&.id)
        end
      end
    end

    def make_components
      ### Make all the components, use the previous Inventory's values if present.
      @component_ids = Component.all.pluck(:id)
      @component_ids.each do |c|
        old_component_count = Count.where(inventory_id: @latest_id).where(component_id: c).last
        component_count = old_component_count.present? ? duplicate(old_component_count) : create_component(c)

        if @tech_ids.any?
          bypass(component_count) if @tech_ids.include?(component_count.technology&.id)
        end
      end
    end

    def duplicate(old_count)
      new_count = old_count.dup
      new_count.tap do |c|
        c.inventory_id = @inventory.id
        c.extrapolated_count = 0
        c.user_id = nil
        c.save
      end

      new_count.reload
    end

    def create_part(id)
      Count.where(inventory_id: @inventory.id, part_id: id).first_or_create
    end

    def create_material(id)
      Count.where(inventory_id: @inventory.id, material_id: id).first_or_create
    end

    def create_component(id)
      Count.where(inventory_id: @inventory.id, component_id: id).first_or_create
    end

    def bypass(count)
      count.update(user_id: @user_id)
    end
  end
end
