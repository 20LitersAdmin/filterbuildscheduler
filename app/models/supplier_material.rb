class SupplierMaterial < ApplicationRecord
  acts_as_paranoid

  belongs_to :supplier, inverse_of: :supplier_materials
  belongs_to :material, inverse_of: :supplier_materials

  validates :supplier_id, :material_id, :min_order, :quantity_per_box, presence: true
  validates :min_order, :minimum_on_hand, :quantity_per_box, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  monetize :price_cents, :shipping_cents, :wire_transfer_cents, :additional_cost_cents, numericality: { greater_than_or_equal_to: 0 }
end