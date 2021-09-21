# frozen_string_literal: true

class PriceCalculationJob < ApplicationJob
  queue_as :price_calc

  def perform(*_args)
    Technology.update_all(price_cents: 0)
    Component.update_all(price_cents: 0)

    # starting with the "lowest" nodes is crucial to make sure prices
    # get summed as we traverse upwards towards the roots
    Assembly.descending.each do |a|
      # reclaculates a.price_cents on save
      a.save
      a.reload

      c = a.combination
      c.update_columns(price_cents: c.price_cents + a.price_cents)
    end
  end
end
