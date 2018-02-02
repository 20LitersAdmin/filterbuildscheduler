class Material < ApplicationRecord
  acts_as_paranoid

  has_and_belongs_to_many :technologies

  has_many :extrapolate_material_parts, dependent: :destroy, inverse_of: :material
  has_many :parts, through: :extrapolate_material_parts
  accepts_nested_attributes_for :extrapolate_material_parts, allow_destroy: true

  has_many :counts, dependent: :destroy

  has_many :supplier_materials, dependent: :destroy, inverse_of: :material
  has_many :suppliers, through: :supplier_materials
  accepts_nested_attributes_for :supplier_materials, allow_destroy: true

  monetize :price_cents, numericality: { greater_than_or_equal_to: 0 }
  monetize :additional_cost_cents, numericality: { greater_than_or_equal_to: 0 }
end
