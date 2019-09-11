# frozen_string_literal: true

class Part < ApplicationRecord
  acts_as_paranoid

  has_many :extrapolate_technology_parts, dependent: :destroy, inverse_of: :part
  has_many :technologies, through: :extrapolate_technology_parts
  accepts_nested_attributes_for :extrapolate_technology_parts, allow_destroy: true

  has_many :extrapolate_component_parts, dependent: :destroy, inverse_of: :part
  has_many :components, through: :extrapolate_component_parts
  accepts_nested_attributes_for :extrapolate_component_parts, allow_destroy: true

  has_many :extrapolate_material_parts, dependent: :destroy, inverse_of: :part
  has_many :materials, through: :extrapolate_material_parts
  accepts_nested_attributes_for :extrapolate_material_parts, allow_destroy: true

  has_many :counts, dependent: :destroy

  belongs_to :supplier, optional: true

  monetize :price_cents, allow_nil: true, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(deleted_at: nil) }

  def available
    if latest_count.present?
      latest_count.available
    else
      0
    end
  end

  def cprice
    return price unless (price.nil? || price.zero?) && made_from_materials?

    emp = extrapolate_material_parts.first

    return Money.new(0) if emp.nil?

    emp.material.price / emp.parts_per_material
  end

  def latest_count
    Count.where(inventory: Inventory.latest_completed, part: self).first
  end

  def on_order?
    last_ordered_at.present? && (last_received_at.nil? || last_ordered_at > last_received_at)
  end

  def picture
    begin
      ActionController::Base.helpers.asset_path('uids/' + uid + '.jpg')
    rescue => error
      'http://placekitten.com/140/140'
    end
  end

  def per_technology
    if extrapolate_technology_parts.first.present?
      per_tech = extrapolate_technology_parts.first.parts_per_technology.to_f
    elsif extrapolate_component_parts.first.present?
      ppc = extrapolate_component_parts.first.parts_per_component.to_f
      component = extrapolate_component_parts.first.component
      cpt = component.extrapolate_technology_components.first.components_per_technology.to_f
      per_tech = ppc.to_f * cpt
    else
      per_tech = 0.0
    end

    per_tech
  end

  def reorder_total_cost
    min_order * price
  end

  def required?
    if extrapolate_technology_parts.any?
      extrapolate_technology_parts.first.required?
    else
      false
    end
  end

  def technology
    # The path from parts to technologies can vary:
    # Part ->(extrap_technology_parts)-> Technology
    # Part ->(extrap_component_parts)-> Component ->(extrap_component_parts)-> Technology

    # FLAWED: when one part belongs to two technologies, then .first is a bad idea

    if technologies.first.present?
      technologies.first
    elsif extrapolate_component_parts.first.present?
      components.first.technologies.first
    end
  end

  def uid
    'P' + id.to_s.rjust(3, '0')
  end
end
