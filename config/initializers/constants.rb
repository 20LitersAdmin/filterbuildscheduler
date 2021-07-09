# frozen_string_literal: true

module Constants
  module Inventory
    COUNT_BTN_TEXT = { receiving: 'Receive', shipping: 'Ship', manual: 'Count', event: 'Adjust', unknown: 'Adjust' }.freeze
    public_constant :COUNT_BTN_TEXT
  end

  module Email
    INTERNAL_DOMAINS = %w[@20liters @twentyliters @20litres @twentylitres].freeze
    public_constant :INTERNAL_DOMAINS
  end
end
