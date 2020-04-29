# frozen_string_literal: true

class ExtrapolateTechnologyPart < ApplicationRecord
  acts_as_paranoid

  belongs_to :technology, inverse_of: :extrapolate_technology_parts
  belongs_to :part, inverse_of: :extrapolate_technology_parts

  validates :technology_id, :part_id, :parts_per_technology, presence: true
  validates :parts_per_technology, numericality: { greater_than: 0 }

  def part_price
    if part.made_from_materials? && part.price_cents == 0
      ary = []
      part.extrapolate_material_parts.each do |emp|
        ary << emp.material.price / emp.parts_per_material.to_f
      end
      ary.sum
    else
      part.price
    end
  end

  def price_per_technology
    part_price * parts_per_technology.to_f
  end
end
