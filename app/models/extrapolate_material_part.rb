# frozen_string_literal: true

class ExtrapolateMaterialPart < ApplicationRecord
  belongs_to :material, inverse_of: :extrapolate_material_parts
  belongs_to :part, inverse_of: :extrapolate_material_parts

  validates :material_id, :part_id, :parts_per_material, presence: true
  validates :parts_per_material, numericality: { greater_than: 0 }

  def material_price
    material.price
  end

  def part_price
    if part.made_from_materials? && part.price_cents.zero?
      material.price / parts_per_material.to_f
    else
      part.price
    end
  end
end
