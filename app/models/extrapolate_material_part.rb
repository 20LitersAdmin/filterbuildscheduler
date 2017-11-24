class ExtrapolateMaterialPart < ApplicationRecord
  belongs_to :material
  belongs_to :part

  validates :material_id, :part_id, :parts_per_material, presence: true
  validates :parts_per_material, numericality: { only_integer: true }
end
