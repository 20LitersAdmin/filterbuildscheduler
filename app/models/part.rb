class Part < ApplicationRecord
  acts_as_paranoid

  has_many :extrapolate_technology_parts
  has_many :technologies, through: :extrapolate_technology_parts

  has_many :extrapolate_component_parts
  has_many :components, through: :extrapolate_component_parts

  has_many :extrapolate_material_parts
  has_many :materials, through: :extrapolate_material_parts

  has_many :counts, dependent: :destroy

  monetize :price_cents, allow_nil: true, numericality: { greater_than_or_equal_to: 0 }
  monetize :additional_cost_cents, allow_nil: true, numericality: { greater_than_or_equal_to: 0 }

  def id_ary
    self.map { |o| o.id }
  end
end
