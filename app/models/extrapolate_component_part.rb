class ExtrapolateComponentPart < ApplicationRecord
  belongs_to :component, inverse_of: :extrapolate_component_parts
  belongs_to :part, inverse_of: :extrapolate_component_parts

  validates :component_id, :part_id, :parts_per_component, presence: true
  validates :parts_per_component, numericality: { only_integer: true }
end
