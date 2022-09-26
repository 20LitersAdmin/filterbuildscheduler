# frozen_string_literal: true

# config/initializers/psych.rb

# https://stackoverflow.com/a/71192990

module YAML
  class << self
    alias_method :load, :unsafe_load if YAML.respond_to? :unsafe_load
  end
end
