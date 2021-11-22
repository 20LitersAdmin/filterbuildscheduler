# frozen_string_literal: true

module Constants
  module Inventory
    COUNT_BTN_TEXT = { receiving: 'Receive', shipping: 'Ship', manual: 'Count', event: 'Adjust' }.freeze
    public_constant :COUNT_BTN_TEXT
  end

  module Email
    INTERNAL_DOMAINS = %w[@20liters @twentyliters @20litres @twentylitres].freeze

    # implementation of URI::MailTo::EMAIL_REGEXP, except the requirements for start of string and end of string matching.
    REGEX = %r/[a-zA-Z0-9.!\#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*/
    public_constant :INTERNAL_DOMAINS
    public_constant :REGEX
  end

  module UID
    CHAR = {
      'C': 'Component',
      'M': 'Material',
      'P': 'Part',
      'T': 'Technology'
    }.freeze

    REGEX = /^(C|M|P|T)[0-9]{3}$/

    URL_REGEX = /(C|M|P|T)[0-9]{3}/

    public_constant :CHAR
    public_constant :REGEX
    public_constant :URL_REGEX
  end
end
