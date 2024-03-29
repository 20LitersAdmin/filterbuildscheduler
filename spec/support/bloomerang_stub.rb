# frozen_string_literal: true

# rubocop:disable Style/StaticClass, Style/RedundantSelf
module Bloomerang
  class Base
    # block Bloomerang gem from sending
    def self.get(path, _params = {})
      self.full_url(path)
    end

    def self.post(path, _params, _body)
      self.full_url(path)
    end

    def self.put(path, _params, _body)
      self.full_url(path)
    end

    def self.delete(path, _params = {})
      self.full_url(path)
    end

    def self.full_url(path)
      "TEST MODE: #{Bloomerang.configuration.api_url}#{path}"
    end
  end
end
# rubocop:enable Style/StaticClass, Style/RedundantSelf
