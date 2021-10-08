# frozen_string_literal: true

class PriceCalculationJob < ApplicationJob
  queue_as :price_calc

  def perform(*_args)
    ActiveRecord::Base.logger.level = 1

    puts '========================= Starting PriceCalculationJob ========================='

    puts 'Setting Technology and Component prices to 0'
    # skip callbacks to avoid an infinite loop of triggering this job
    Technology.update_all(price_cents: 0)
    Component.update_all(price_cents: 0)

    # starting with the "lowest" nodes is crucial to make sure prices
    # get summed as we traverse upwards towards the roots
    puts 'Looping over Assemblies'
    Assembly.descending.each do |a|
      # reclaculates a.price_cents on save
      a.save
      a.reload

      c = a.combination
      # skip callbacks to avoid an infinite loop of triggering this job
      c.update_columns(price_cents: c.price_cents + a.price_cents)
    end

    puts '========================= FINISHED QuantityAndDepthCalculationJob ========================='

    ActiveRecord::Base.logger.level = 0
  end
end
