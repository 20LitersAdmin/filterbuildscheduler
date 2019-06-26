# frozen_string_literal: true

class Component < ApplicationRecord
  acts_as_paranoid

  has_many :extrapolate_technology_components, dependent: :destroy, inverse_of: :component
  has_many :technologies, through: :extrapolate_technology_components
  accepts_nested_attributes_for :extrapolate_technology_components, allow_destroy: true

  has_many :extrapolate_component_parts, dependent: :destroy, inverse_of: :component
  has_many :parts, through: :extrapolate_component_parts
  accepts_nested_attributes_for :extrapolate_component_parts, allow_destroy: true

  has_many :counts, dependent: :destroy
  scope :active, -> { where(deleted_at: nil) }
  scope :required, -> { joins(:extrapolate_technology_components).where.not(completed_tech: true).where(extrapolate_technology_components: {required: true }) }

  def available
    if latest_count.present?
      latest_count.available
    else
      0
    end
  end

  def latest_count
    Count.where(inventory: Inventory.latest_completed, component: self).first
  end

  def picture
    begin
      ActionController::Base.helpers.asset_path('uids/' + uid + '.jpg')
    rescue => error
      'http://placekitten.com/140/140'
    end
  end

  def per_technology
    if extrapolate_technology_components.any?
      extrapolate_technology_components.first.components_per_technology.to_i
    else
      1
    end
  end

  def price
    ary = []
    extrapolate_component_parts.each do |ecp|
      next if ecp.part.nil?

      if ecp.part.made_from_materials? && ecp.part.price_cents.zero?
        emp = ecp.part.extrapolate_material_parts.first
        ary << emp.part_price * ecp.parts_per_component.to_i
      else
        ary << ecp.part_price * ecp.parts_per_component.to_i
      end
    end
    ary.sum
  end

  def required?
    if extrapolate_technology_components.any?
      extrapolate_technology_components.first.required?
    else
      false
    end
  end

  def technology
    technologies.first
  end

  def total
    if latest_count
      latest_count.total
    else
      0
    end
  end

  def uid
    'C' + id.to_s.rjust(3, '0')
  end
end
