# frozen_string_literal: true

class ExtrapolateTechnologyMaterial < ApplicationRecord
  acts_as_paranoid

  belongs_to :material, inverse_of: :extrapolate_technology_materials
  belongs_to :technology, inverse_of: :extrapolate_technology_materials

  validates :material_id, :technology_id, :materials_per_technology, presence: true
  validates_numericality_of :materials_per_technology
  validates :materials_per_technology, numericality: { greater_than: 0 }

  scope :active, -> { where(deleted_at: nil) }

  def technology
    return unless technology_id.present?

    Technology.with_deleted.find(technology_id)
  end

  def material
    return unless material_id.present?

    Material.with_deleted.find(material_id)
  end

  def material_price
    material.price
  end

  def price_per_technology
    material.price / materials_per_technology.to_f
  end
end
