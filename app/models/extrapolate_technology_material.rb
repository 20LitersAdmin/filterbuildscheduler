# frozen_string_literal: true

class ExtrapolateTechnologyMaterial < ApplicationRecord
  belongs_to :material, inverse_of: :extrapolate_technology_materials
  belongs_to :technology, inverse_of: :extrapolate_technology_materials

  validates :material_id, :technology_id, :materials_per_technology, presence: true
  validates_numericality_of :materials_per_technology
  validates :materials_per_technology, numericality: { greater_than: 0 }

  def material_price
    material.price
  end

  def price_per_technology
    material.price / materials_per_technology.to_f
  end
end
