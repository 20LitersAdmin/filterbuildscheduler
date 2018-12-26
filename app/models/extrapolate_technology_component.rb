# frozen_string_literal: true

class ExtrapolateTechnologyComponent < ApplicationRecord
  belongs_to :component, inverse_of: :extrapolate_technology_components
  belongs_to :technology, inverse_of: :extrapolate_technology_components

  validates :component_id, :technology_id, :components_per_technology, presence: true
  validates :components_per_technology, numericality: { only_integer: true }

  def component_price
    component.price
  end

  def price_per_technology
    component.price * components_per_technology
  end
end
