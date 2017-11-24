class ExtrapolateComponentPart < ApplicationRecord
  belongs_to :component
  belongs_to :part

  validates :component_id, :part_id, :parts_per_component, presence: true
  validates :parts_per_component, numericality: { only_integer: true }
end
