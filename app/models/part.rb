class Part < ApplicationRecord
  acts_as_paranoid

  has_many :extrapolate_technology_parts, dependent: :destroy, inverse_of: :part
  has_many :technologies, through: :extrapolate_technology_parts
  accepts_nested_attributes_for :extrapolate_technology_parts, allow_destroy: true

  has_many :extrapolate_component_parts, dependent: :destroy, inverse_of: :part
  has_many :components, through: :extrapolate_component_parts
  accepts_nested_attributes_for :extrapolate_component_parts, allow_destroy: true

  has_many :extrapolate_material_parts, dependent: :destroy, inverse_of: :part
  has_many :materials, through: :extrapolate_material_parts
  accepts_nested_attributes_for :extrapolate_material_parts, allow_destroy: true

  has_many :counts, dependent: :destroy

  has_and_belongs_to_many :suppliers

  monetize :price_cents, allow_nil: true, numericality: { greater_than_or_equal_to: 0 }
  monetize :additional_cost_cents, allow_nil: true, numericality: { greater_than_or_equal_to: 0 }
  monetize :shipping_cost_cents, allow_nil: true, numericality: { greater_than_or_equal_to: 0 }
  monetize :wire_transfer_cost_cents, allow_nil: true, numericality: { greater_than_or_equal_to: 0 }
end
