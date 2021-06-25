# frozen_string_literal: true

class ExtrapolateMaterialPart < ApplicationRecord
  acts_as_paranoid

  # belongs_to :material, inverse_of: :extrapolate_material_parts
  # belongs_to :part, inverse_of: :extrapolate_material_parts

  validates :material_id, :part_id, :parts_per_material, presence: true
  validates :parts_per_material, numericality: { greater_than: 0 }

  scope :active, -> { where(deleted_at: nil) }

  def part
    return unless part_id.present?

    Part.with_deleted.find(part_id)
  end

  def material
    return unless material_id.present?

    Material.with_deleted.find(material_id)
  end

  def material_price
    material.price
  end

  def part_price
    if part.made_from_materials? && part.price_cents.zero? && part.extrapolate_material_parts.any?
      material.price / parts_per_material.to_f
    else
      part.price
    end
  end
end
