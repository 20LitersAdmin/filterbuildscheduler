class Material < ApplicationRecord
  acts_as_paranoid
  has_and_belongs_to_many :parts
  has_and_belongs_to_many :counts

  monetize :price_cents
  monetize :additional_costs_cents
end
