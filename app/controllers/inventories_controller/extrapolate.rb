class InventoriesController
  class Extrapolate
    def initialize(inventory)
      @inventory = inventory
      @counts_components = @inventory.counts.where.not(component_id: nil)

      @counts_components.each do |c|
        # Find parts that make up the component from extrapolate_component_parts
        c.component.extrapolate_component_parts.each do |e|
          # Find the count for the related part
          counts_part = @inventory.counts.where(part_id: e.part_id).first
          # Do the math based upon parts_per_component and .available
          extrapolated_count = c.available * e.parts_per_component
          # Add this val to extrapolated_count for the part record
          counts_part.extrapolated_count = extrapolated_count
          counts_part.save
        end
      end
    end
  end

end
