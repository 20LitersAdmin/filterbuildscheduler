class ExtrapolateTechnologyMaterial < ApplicationRecord
  belongs_to :material, inverse_of: :extrapolate_technology_materials
  belongs_to :technology, inverse_of: :extrapolate_technology_materials

  validates :material_id, :technology_id, :materials_per_technology, presence: true
  validates_numericality_of :materials_per_technology
end
