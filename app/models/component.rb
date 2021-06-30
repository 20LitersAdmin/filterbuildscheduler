# frozen_string_literal: true

class Component < ApplicationRecord
  # acts_as_paranoid

  # has_many :extrapolate_technology_components, dependent: :destroy, inverse_of: :component
  # has_many :technologies, through: :extrapolate_technology_components
  # accepts_nested_attributes_for :extrapolate_technology_components, allow_destroy: true

  # has_many :extrapolate_component_parts, dependent: :destroy, inverse_of: :component
  # has_many :parts, through: :extrapolate_component_parts
  # accepts_nested_attributes_for :extrapolate_component_parts, allow_destroy: true

  # has_many :counts, dependent: :destroy

  # scope :active, -> { where(deleted_at: nil) }
  # scope :required, -> { joins(:extrapolate_technology_components).where.not(completed_tech: true).where(extrapolate_technology_components: { required: true }) }

  # TODO: TEMP merge function
  def replace_with(component_id)
    Assembly.where(combination: self).update_all(combination_id: component_id)

    Assembly.where(item: self).update_all(item_id: component_id)

    self
  end

  # associations through Assembly
  def technologies
    Technology.joins(:assemblies).where('assemblies.item_id = ? AND assemblies.item_type = ?', id, 'Component')
  end

  def superassemblies
    Assembly.where(item_id: id, item_type: 'Component')
  end

  def supercomponents
    Component.find_by_sql(
      "SELECT * FROM components
      INNER JOIN assemblies
      ON assemblies.combination_id = components.id
      AND assemblies.combination_type = 'Component'
      WHERE assemblies.item_type = 'Component'
      AND assemblies.item_id = #{id}"
    )
  end

  def subassemblies
    Assembly.where(combination_id: id, combination_type: 'Component')
  end

  def subcomponents
    Component.find_by_sql(
      "SELECT * FROM components
      INNER JOIN assemblies
      ON assemblies.item_id = components.id
      AND assemblies.item_type = 'Component'
      WHERE assemblies.combination_type = 'Component'
      AND assemblies.combination_id = #{id}"
    )
  end

  # end associations

  def parts
    Part.joins(:assemblies).where('assemblies.combination_id = ? AND assemblies.combination_type = ?', id, 'Component')
  end

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

  def price
    ary = []
    extrapolate_component_parts.each do |ecp|
      next if ecp&.part.nil?

      if ecp.part.made_from_materials? && ecp.part.price_cents.zero? && ecp.part.extrapolate_material_parts.any?
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
