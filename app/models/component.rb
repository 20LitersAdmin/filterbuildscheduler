# frozen_string_literal: true

class Component < ApplicationRecord
  # TODO: Second deployment
  # include Discard::Model

  # TODO: Second deployment
  # has_one_attached :image, dependent: :purge

  # TODO: Second deployment
  # scope :active, -> { kept }

  before_destroy :dependent_destroy_assemblies

  # TODO: Second deployment
  monetize :price_cents, numericality: { greater_than_or_equal_to: 0 }

  # TODO: TEMP merge function
  def replace_with(component_id)
    Assembly.where(combination: self).update_all(combination_id: component_id)

    Assembly.where(item: self).update_all(item_id: component_id)

    self
  end

  # associations through Assembly
  def technologies
    Technology.where('quantities ? :key', key: uid)
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

  # TODO: fix this or un-use it
  def latest_count
    Count.where(inventory: Inventory.latest_completed, component: self).first
  end

  # TODO: replace this with image
  def picture
    begin
      ActionController::Base.helpers.asset_path('uids/' + uid + '.jpg')
    rescue => error
      'http://placekitten.com/140/140'
    end
  end

  # TODO: replace this with price_cents
  def cprice
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

  # TODO: un-use this
  def required?
    if extrapolate_technology_components.any?
      extrapolate_technology_components.first.required?
    else
      false
    end
  end

  # TODO: un-use this
  def technology
    technologies.first
  end

  # TODO: un-use this
  def total
    if latest_count
      latest_count.total
    else
      0
    end
  end

  def uid
    "C#{id.to_s.rjust(3, '0')}"
  end

  private

  def dependent_destroy_assemblies
    superassemblies.destroy_all
    subassemblies.destroy_all
  end
end
