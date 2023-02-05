module Bloomerang
  class Base
    # block Bloomerang gem from sending
    def self.get(path, params = {})
      self.full_url(path)
    end

    def self.post(path, params, body)
      self.full_url(path)
    end

    def self.put(path, params, body)
      self.full_url(path)
    end

    def self.delete(path, params = {})
      self.full_url(path)
    end

    def self.full_url(path)
      "TEST MODE: #{Bloomerang.configuration.api_url}#{path}"
    end
  end
end