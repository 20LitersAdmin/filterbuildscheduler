# frozen_string_literal: true

class ExtrapolateTechnologyComponent < ApplicationRecord
  acts_as_paranoid

  belongs_to :component, inverse_of: :extrapolate_technology_components
  belongs_to :technology, inverse_of: :extrapolate_technology_components

  validates :component_id, :technology_id, :components_per_technology, presence: true
  validates :components_per_technology, numericality: { greater_than: 0 }

  scope :active, -> { where(deleted_at: nil) }

  def component
    Component.with_deleted.find(component_id)
  end

  def technology
    Technology.with_deleted.find(technology_id)
  end

  def component_price
    component.price
  end

  def price_per_technology
    component.price * components_per_technology.to_f
  end
end
