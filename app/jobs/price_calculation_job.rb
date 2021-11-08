# frozen_string_literal: true

class PriceCalculationJob < ApplicationJob
  queue_as :price_calc

  def perform(*_args)
    ActiveRecord::Base.logger.level = 1

    puts '========================= Starting PriceCalculationJob ========================='

    puts 'Setting Technology, Component, and Part#made_from_material prices to 0'
    # skip callbacks to avoid an infinite loop of triggering this job
    Technology.update_all(price_cents: 0)
    Component.update_all(price_cents: 0)
    Part.made_from_material.update_all(price_cents: 0)

    # recalculate Part#made_from_material before looping over assemblies
    puts 'Setting prices for Parts made from Materials'
    Part.made_from_material.each do |part|
      q_from_m = part.quantity_from_material
      if q_from_m.zero? || q_from_m.nil?
        puts "*** #{part.uid} has no quantity_from_material!!! It was skipped ***"
        next
      end

      # round up to the nearest cent using .ceil()
      new_price_cents = (part.material.price_cents / part.quantity_from_material).ceil

      part.update_columns(price_cents: new_price_cents)
    end

    # starting with the "lowest" nodes is crucial to make sure prices
    # get summed as we traverse upwards towards the roots
    puts 'Looping over Assemblies to set their prices and their combination\'s price'
    Assembly.descending.each do |a|
      # reclaculates a.price_cents on save
      a.save
      a.reload

      c = a.combination
      # skip callbacks to avoid an infinite loop of triggering this job
      # c.price_cents + a.price_cents is sorta just +=
      c.update_columns(price_cents: c.price_cents + a.price_cents)
    end

    puts '========================= FINISHED QuantityAndDepthCalculationJob ========================='

    ActiveRecord::Base.logger.level = 0
  end
end
