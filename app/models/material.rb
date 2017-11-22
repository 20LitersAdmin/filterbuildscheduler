class Material < ApplicationRecord
  acts_as_paranoid
  has_and_belongs_to_many :parts
  has_and_belongs_to_many :counts

  monetize :price_cents, allow_nil: true, numericality: { greater_than_or_equal_to: 0 }
  monetize :additional_cost_cents, allow_nil: true, numericality: { greater_than_or_equal_to: 0 }
end
