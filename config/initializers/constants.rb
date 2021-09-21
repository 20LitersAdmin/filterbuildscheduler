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

  module UID
    CHAR = {
      'C': 'Component',
      'M': 'Material',
      'P': 'Part',
      'T': 'Technology'
    }.freeze

    REGEX = /^(C|M|P|T)[0-9]{3}$/.freeze

    URL_REGEX = /(C|M|P|T)[0-9]{3}/.freeze

    public_constant :CHAR
    public_constant :REGEX
    public_constant :URL_REGEX
  end
end
