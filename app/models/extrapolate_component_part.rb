# frozen_string_literal: true

class ExtrapolateComponentPart < ApplicationRecord
  belongs_to :component, inverse_of: :extrapolate_component_parts
  belongs_to :part, inverse_of: :extrapolate_component_parts

  validates :component_id, :part_id, :parts_per_component, presence: true
  validates :parts_per_component, numericality: { greater_than: 0 }

  def part_price
    if part.made_from_materials? && part.price_cents.zero?
      ary = []
      emp = part.extrapolate_material_parts.first
      ary << emp.material.price / emp.parts_per_material.to_f
      ary.sum
    else
      part.price
    end
  end

  def price_per_component
    part_price * parts_per_component.to_f
  end
end
