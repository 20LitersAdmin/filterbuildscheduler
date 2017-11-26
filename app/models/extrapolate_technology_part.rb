class ExtrapolateTechnologyPart < ApplicationRecord
  belongs_to :technology, inverse_of: :extrapolate_technology_parts
  belongs_to :part, inverse_of: :extrapolate_technology_parts

  validates :technology_id, :part_id, :parts_per_technology, presence: true
  validates :parts_per_technology, numericality: { only_integer: true }
end
