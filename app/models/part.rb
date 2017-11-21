class Part < ApplicationRecord
  acts_as_paranoid
  has_and_belongs_to_many :materials
  has_and_belongs_to_many :technologies
  has_and_belongs_to_many :components
  has_and_belongs_to_many :counts

  monetize :price_cents
  monetize :additional_costs_cents
end
