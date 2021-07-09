# frozen_string_literal: true

class MaterialsPart < ApplicationRecord
  belongs_to :material
  belongs_to :part

  validates :quantity, numericality: { greater_than: 0 }
  before_save :calculate_price_for_part
  after_save :recalculate_technology_quantities
  after_destroy :recalculate_technology_quantities

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
