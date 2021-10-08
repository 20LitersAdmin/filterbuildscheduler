# frozen_string_literal: true

class Count < ApplicationRecord
  attr_accessor :reorder

  belongs_to :inventory
  belongs_to :user, optional: true
  belongs_to :item, polymorphic: true

  validates_presence_of :inventory_id

  # TODO: un-use
  scope :not_components, -> { where(component_id: nil) }
  scope :changed, -> { where.not(user_id: nil) }
  scope :uncounted, -> { where(user_id: nil) }

  def available
    loose_count.to_i + box_count
  end

  def box_count
    item.quantity_per_box * unopened_boxes_count.to_i
  end

  # TODO: fix or remove
  # def can_produce_x_parent
  #   return 0 if available.zero?

  #   case type
  #   when 'material'
  #     # Materials are larger than parts (1 material makes many parts)
  #     material.extrapolate_material_parts.any? ? available * material.extrapolate_material_parts.first.parts_per_material.to_i : available
  #   when 'part'
  #     part.extrapolate_component_parts.any? ? available / part.extrapolate_component_parts.first.parts_per_component.to_i : available
  #   when 'component'
  #     available / item.per_technology
  #   end
  # end

  # TODO: fix or remove
  # def can_produce_x_tech
  #   available.zero? ? 0 : available / item.per_technology
  # end

  # def diff_from_previous(field)
  #   # coerce nil to 0 if necessary with .to_i
  #   case field
  #   when 'loose'
  #     loose_count.to_i - item.loose_count
  #   when 'box'
  #     unopened_boxes_count.to_i - item.box_count
  #   when 'available'
  #     available.to_i - item.available_count
  #   else
  #     0
  #   end
  # end

  def group_by_tech
    item.technologies.map(&:id).min || 999
  end

  def link_text
    # return the correct link text for inventory/:id/edit
    return 'Edit' unless user_id.nil?

    return 'Loose Count' if partial_box

    return 'Box Count' if partial_loose

    Constants::Inventory::COUNT_BTN_TEXT[inventory.type_for_params.to_sym]
  end

  def link_class
    return 'blue' unless user_id.nil?

    return 'empty' if partial_box || partial_loose

    'yellow'
  end
end
