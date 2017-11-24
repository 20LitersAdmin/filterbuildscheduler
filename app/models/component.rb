class Component < ApplicationRecord
  acts_as_paranoid

  has_many :extrapolate_technology_components
  has_many :technologies, through: :extrapolate_technology_components

  has_many :extrapolate_component_parts
  has_many :parts, through: :extrapolate_component_parts

  has_many :counts, dependent: :destroy

  def id_ary
    map { |o| o.id }
  end
end
