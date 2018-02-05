class Material < ApplicationRecord
  acts_as_paranoid

  has_and_belongs_to_many :technologies

  has_many :extrapolate_material_parts, dependent: :destroy, inverse_of: :material
  has_many :parts, through: :extrapolate_material_parts
  accepts_nested_attributes_for :extrapolate_material_parts, allow_destroy: true

  has_many :counts, dependent: :destroy
  
  belongs_to :supplier

  monetize :price_cents, :additional_cost_cents, numericality: { greater_than_or_equal_to: 0 }

  def reorder_total_cost
    (min_order * price ) + shipping_cost + wire_transfer_cost
  end
end
