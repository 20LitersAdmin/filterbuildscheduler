# frozen_string_literal: true

class EventsController
  class SubtractSubsets
    def initialize(loose, box, event, inventory)

      technology = event.technology

      tech_component = technology.primary_component

      new_tech_available = loose + (tech_component.quantity_per_box * box)

      technology.extrapolate_technology_components.where(required: true).each do |etc|
        # don't subtract from the primary component
        return if etc.component == tech_component

        quantity = new_tech_available * etc.components_per_technology.to_i

        count = inventory.counts.where(component_id: etc.component_id).first

        subtract!(quantity, count)
      end

      technology.extrapolate_technology_parts.where(required: true).each do |etp|
        quantity = new_tech_available * etp.parts_per_technology.to_i

        count = inventory.counts.where(part_id: etp.part_id).first

        subtract!(quantity, count)
      end

      technology.extrapolate_technology_materials.where(required: true).each do |etm|
        quantity = new_tech_available * etm.materials_per_technology.to_i

        count = inventory.counts.where(material_id: etm.material_id).first

        subtract!(quantity, count)
      end
    end

    def subtract!(quantity, count)
      if count.available < quantity
        # we found them somehow, but it cleaned us out
        # or, we made them from something else... but this gets messy.
        # SCENARIO1: 3-inch core w/O-ring (component):
        #  - we didn't have enough with o-rings already on them, so:
        #   + we should zero them out and subtract the difference of quantity - count.available from both O-rings and 3-inch cores
        #  - but we actually made more 3-inch cores w/O-rings during the event than we needed for the final, so the inventory will still be off
        # The real question is how deep should the subtractions go? Max level could be 4 deep and still not provide additional accuracy.
        count.loose_count = 0
        count.unopened_boxes_count = 0

      elsif count.loose_count < quantity
        # we had to pull from unopened boxes
        q_per_box = count.item.quantity_per_box
        pull_from_boxes = quantity - count.loose_count
        boxes_to_open = (pull_from_boxes.to_f / q_per_box).ceil

        # remove those boxes from the count
        count.unopened_boxes_count -= boxes_to_open

        # add those now-unboxed-parts to the loose_count
        count.loose_count += (boxes_to_open * q_per_box) - pull_from_boxes
      else # count.loose_count > quantity
        # we had enough in the loose_count
        count.loose_count -= quantity
      end

      count.save
    end
  end
end
