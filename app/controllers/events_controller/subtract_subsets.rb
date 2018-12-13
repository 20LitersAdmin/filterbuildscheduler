# frozen_string_literal: true

class EventsController
  class SubtractSubsets
    def initialize(loose, box, event, inventory)
      technology = event.technology

      # THIS IS FLAWED!!!
      # SWITCH TO THIS:
      # technology.extrapolate_technology_components
        # iterate over and subtract against components_per_technology
      # technology.extrapolate_technology_parts
        # iterate over and subtract against components_per_technology
      # technology.extrapolate_technology_materials
        # iterate over and subtract against materials_per_technology

      # If there's no primary component, just bail
      return unless technology.primary_component.present?
      
      # Find the component that represents the completed technology
      tech_component = technology.primary_component

      # How many new, completed technologies in total?
      new_tech_available = loose + (tech_component.quantity_per_box * box)

      # Find that component count among all the counts
      count_component = inventory.counts.where(component_id: tech_component.id).first_or_initialize



      count_component.component.extrapolate_component_parts.each do |e|
        # Find the count for the related part
        counts_part = inventory.counts.where(part_id: e.part_id).first
        
        # Do the math
        subtract = new_tech_available * e.parts_per_component

        if counts_part.available < subtract
          # we found them somehow, but it cleaned us out
          counts_part.loose_count = 0
          counts_part.unopened_boxes_count = 0
        elsif counts_part.loose_count < subtract
          q_per_box = counts_part.part.quantity_per_box
          # we had to open one or more boxes
          pull_from_boxes = subtract - counts_part.loose_count
          boxes_to_open = (pull_from_boxes.to_f / q_per_box).ceil

          # remove those boxes from the count
          counts_part.unopened_boxes_count -= boxes_to_open

          # add those now-unboxed-parts to the loose_count
          counts_part.loose_count += (boxes_to_open * q_per_box)

          # remove the used parts from the count
          counts_part.loose_count -= subtract
        end

        counts_part.save
      end
    end
  end
end
