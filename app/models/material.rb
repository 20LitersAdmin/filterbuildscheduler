# frozen_string_literal: true

class Material < ApplicationRecord
  # acts_as_paranoid

  # has_many :extrapolate_material_parts, dependent: :destroy, inverse_of: :material
  has_many :parts, through: :materials_parts
  # accepts_nested_attributes_for :extrapolate_material_parts, allow_destroy: true

  # has_many :extrapolate_technology_materials, dependent: :destroy, inverse_of: :material
  # has_many :technologies, through: :extrapolate_technology_materials
  # accepts_nested_attributes_for :extrapolate_technology_materials, allow_destroy: true

  # has_many :counts, dependent: :destroy

  belongs_to :supplier, optional: true

  monetize :price_cents, allow_nil: true, numericality: { greater_than_or_equal_to: 0 }

  # scope :active, -> { where(deleted_at: nil) }
  scope :required, -> { joins(:extrapolate_technology_materials).where(extrapolate_technology_materials: { required: true }) }

  def available
    if latest_count.present?
      latest_count.available
    else
      0
    end
  end

  def latest_count
    Count.where(inventory: Inventory.latest_completed, material: self).first
  end

  def made_from_materials?
    false
  end

  def on_order?
    last_ordered_at.present? && (last_received_at.nil? || last_ordered_at > last_received_at)
  end

  def owner
    return 'N/A' unless technologies.present?

    technologies.map(&:owner_acronym).uniq.join(',')
  end

  def picture
    begin
      ActionController::Base.helpers.asset_path("uids/#{uid}.jpg")
    rescue => e
      'http://placekitten.com/140/140'
    end
  end

  def per_technology
    if extrapolate_technology_materials.first.present?
      per_tech = extrapolate_technology_materials.first.materials_per_technology
    elsif extrapolate_material_parts.first.present?
      ppm = extrapolate_material_parts.first.parts_per_material.to_f

      part = extrapolate_material_parts.first.part
      ppc = part.extrapolate_component_parts.first.parts_per_component.to_f
      component = part.extrapolate_component_parts.first.component
      cpt = component.extrapolate_technology_components.first.components_per_technology.to_f
      # per_tech = 1.0 / ( ( ppm / ppc ) * cpt )
      per_tech = (cpt * ppc.to_f) / ppm
    else
      per_tech = 0.0
    end

    per_tech
  end

  def reorder?
    available < minimum_on_hand
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

  def tech_names_short
    if technologies.map(&:name).empty?
      'n/a'
    else
      technologies.map { |t| t.name.gsub(' Filter', '').gsub(' for Bucket', '') }.join(', ')
    end
  end

  def uid
    "M#{id.to_s.rjust(3, 0.to_s)}"
  end

  def weeks_to_out
    latest_count.present? ? latest_count.weeks_to_out : 0
  end
end
