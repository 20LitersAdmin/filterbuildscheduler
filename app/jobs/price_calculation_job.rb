# frozen_string_literal: true

class PriceCalculationJob < ApplicationJob
  queue_as :price_calc

  def perform(*_args)
    # NOTE: QuantityAndDepthCalculationJob needs to have been performed recently, to ensure assemblies have a "depth"
    # Since saving or destroying an assembly triggers QuantityAndDepthCalculationJob, we can be confident assemblies have an accurate "depth"

    ActiveRecord::Base.logger.level = 1

    puts '========================= Starting PriceCalculationJob ========================='
    # skip callbacks to avoid an infinite loop of triggering this job
    Technology.update_all(price_cents: 0)
    Component.update_all(price_cents: 0)
    Part.made_from_material.update_all(price_cents: 0)

    # recalculate Part#made_from_material first
    set_prices_for_parts_made_from_materials

    # then loop over assemblies to update the combination price
    sum_prices_for_assembly_combinations

    puts '========================= FINISHED PriceCalculationJob ========================='

    ActiveRecord::Base.logger.level = 0
  end

  def set_prices_for_parts_made_from_materials
    Part.made_from_material.each do |part|
      q_from_m = part.quantity_from_material
      if q_from_m.zero? || q_from_m.nil?
        puts "*** #{part.uid} has no quantity_from_material!!! It was skipped ***"
        next
      end

      # round up to the nearest cent using .ceil()
      new_price_cents = (part.material.price_cents / q_from_m).ceil

      part.update_columns(price_cents: new_price_cents)
    end
  end

  def sum_prices_for_assembly_combinations
    # starting with the "lowest" nodes is crucial to make sure prices
    # get summed as we traverse upwards towards the roots
    Assembly.descending.each do |a|
      # skip callbacks to avoid an infinite loop of triggering this job

      a_price_cents = a.item.price_cents * a.quantity
      # re-calculate the price_cents
      a.update_columns(price_cents: a_price_cents)

      c = a.combination
      # c.price_cents + a.price_cents is sorta just +=
      c.update_columns(price_cents: c.price_cents + a_price_cents)
    end
  end
end
