class ExtrapolateTechnologyComponent < ApplicationRecord
  belongs_to :component
  belongs_to :technology

  validates :component_id, :technology_id, :components_per_technology, presence: true
  validates :components_per_technology, numericality: { only_integer: true }
end
