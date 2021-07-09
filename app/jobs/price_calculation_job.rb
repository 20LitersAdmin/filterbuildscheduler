# frozen_string_literal: true

class PriceCalculationJob < ApplicationJob
  queue_as :price_calc

  def perform(*_args)
    Technology.update_all(price_cents: 0)
    Component.update_all(price_cents: 0)

    Assembly.descending.each do |a|
      # reclaculates a.price_cents on save
      a.save
      a.reload

      c = a.combination
      c.update_columns(price_cents: c.price_cents + a.price_cents)
    end
  end
end
