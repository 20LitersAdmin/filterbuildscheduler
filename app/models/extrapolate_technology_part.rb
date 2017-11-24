class ExtrapolateTechnologyPart < ApplicationRecord
  belongs_to :technology
  belongs_to :part

  validates :technology_id, :part_id, :parts_per_technology, presence: true
  validates :parts_per_technology, numericality: { only_integer: true }
end
