class Component < ApplicationRecord
  acts_as_paranoid

  has_many :extrapolate_technology_components, dependent: :destroy, inverse_of: :component
  has_many :technologies, through: :extrapolate_technology_components
  accepts_nested_attributes_for :extrapolate_technology_components, allow_destroy: true

  has_many :extrapolate_component_parts, dependent: :destroy, inverse_of: :component
  has_many :parts, through: :extrapolate_component_parts
  accepts_nested_attributes_for :extrapolate_component_parts, allow_destroy: true


  has_many :counts, dependent: :destroy

  def technology
    technologies.first
  end

  def per_technology
    if extrapolate_technology_components.any?
      extrapolate_technology_components.first.components_per_technology
    else
      1
    end
  end

  def required?
    if extrapolate_technology_components.any?
      extrapolate_technology_components.first.required?
    else
      false
    end
  end

  def total
    count = Count.where(inventory: Inventory.latest, component: self).first

    if count
      count.total
    else
      0
    end
  end
end
