# frozen_string_literal: true

class MaterialsPart < ApplicationRecord
  belongs_to :material, inverse_of: :materials_parts
  belongs_to :part, inverse_of: :materials_parts

  validates :quantity, numericality: { greater_than: 0 }
  after_save :calculate_price_for_part
  after_save :recalculate_technology_quantities
  after_destroy :recalculate_technology_quantities

  def name
    "#{material_uid}::#{part_uid}"
  end

  def material_uid
    "M#{material_id.to_s.rjust(3, 0.to_s)}"
  end

  def part_uid
    "P#{part_id.to_s.rjust(3, 0.to_s)}"
  end

  private

  def calculate_price_for_part
    return true if material.price_cents.zero?

    # quantity is BigDecimal, price_cents is Integer
    part.update price_cents: (material.price_cents / quantity).round
  end

  def recalculate_technology_quantities
    QuantityAndDepthCalculationJob.perform_later unless Delayed::Job.where(queue: 'quantity_calc').any?
  end
end
