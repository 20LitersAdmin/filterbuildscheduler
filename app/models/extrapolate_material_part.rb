class ExtrapolateMaterialPart < ApplicationRecord
  belongs_to :material, inverse_of: :extrapolate_material_parts
  belongs_to :part, inverse_of: :extrapolate_material_parts

  validates :material_id, :part_id, :parts_per_material, presence: true
  validates :parts_per_material, numericality: { only_integer: true }
end
