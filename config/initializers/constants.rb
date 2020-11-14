# frozen_string_literal: true

module Constants
  class Inventory
    COUNT_BTN_TEXT = { receiving: 'Receive', shipping: 'Ship', manual: 'Count', event: 'Adjust', unknown: 'Adjust' }.freeze
  end

  class Email
    INTERNAL_DOMAINS = %w[@20liters @twentyliters @20litres @twentylitres].freeze
  end
end
