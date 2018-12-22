# frozen_string_literal: true

class Material < ApplicationRecord
  acts_as_paranoid

  has_many :extrapolate_material_parts, dependent: :destroy, inverse_of: :material
  has_many :parts, through: :extrapolate_material_parts
  accepts_nested_attributes_for :extrapolate_material_parts, allow_destroy: true

  has_many :extrapolate_technology_materials, dependent: :destroy, inverse_of: :material
  has_many :technologies, through: :extrapolate_technology_materials
  accepts_nested_attributes_for :extrapolate_technology_materials, allow_destroy: true

  has_many :counts, dependent: :destroy
  
  belongs_to :supplier

  monetize :price_cents, allow_nil: true, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(deleted_at: nil) }

  def uid
    "M" + id.to_s.rjust(3, "0")
  end

  def picture
    begin
      ActionController::Base.helpers.asset_path('uids/' + uid + '.jpg')

    rescue => error
      'http://placekitten.com/140/140'
    end
  end

  def reorder_total_cost
    min_order * price
  end

  def required?
    if extrapolate_technology_materials.any?
      extrapolate_technology_materials.first.required?
    else
      false
    end
  end

  def per_technology
    if extrapolate_material_parts.first.present?
      ppm = extrapolate_material_parts.first.parts_per_material

      part = extrapolate_material_parts.first.part
      ppc = part.extrapolate_component_parts.first.parts_per_component
      component = part.extrapolate_component_parts.first.component
      cpt = component.extrapolate_technology_components.first.components_per_technology
      # per_tech = 1.0 / ( ( ppm / ppc ) * cpt )
      per_tech = (cpt * ppc.to_f ) / ppm
    else
      per_tech = 0.0
    end

    per_tech
  end

  def technology
    # The path from materials to technologies can vary:
    # Material ->(materials_technologies)-> Technology
    # Material ->(extrap_material_parts)-> Part ->(extrap_technology_parts)-> Technology
    # Material ->(extrap_material_parts)-> Part ->(extrap_component_parts)-> Component ->(extrap_component_parts)-> Technology

    if technologies.first.present?
      technologies.first
    elsif extrapolate_material_parts.first.present?
      part = parts.first
      if part.technologies.first.present?
        part.technologies.first
      elsif part.components.first.present?
        component = part.components.first
        component.technologies.first
      end
    end
  end
  
end
