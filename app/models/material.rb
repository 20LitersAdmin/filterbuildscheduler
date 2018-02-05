class Material < ApplicationRecord
  acts_as_paranoid

  has_and_belongs_to_many :technologies

  has_many :extrapolate_material_parts, dependent: :destroy, inverse_of: :material
  has_many :parts, through: :extrapolate_material_parts
  accepts_nested_attributes_for :extrapolate_material_parts, allow_destroy: true

  has_many :counts, dependent: :destroy
  
  belongs_to :supplier

  monetize :price_cents, :additional_cost_cents, :shipping_cost_cents, :wire_transfer_cost_cents, allow_nil: true, numericality: { greater_than_or_equal_to: 0 }

  def reorder_total_cost
    (min_order * price ) + shipping_cost + wire_transfer_cost
  end

  def per_technology
    if extrapolate_material_parts.first.present?
      part = Part.find(extrapolate_material_parts.first.part_id)
      part.per_technology
    else
      0
    end
  end
end
