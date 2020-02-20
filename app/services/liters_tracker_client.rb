# frozen_string_literal: true

class LitersTrackerClient
  include HTTParty

  attr_accessor :as_of_date, :stat_ary

  base_uri 'https://track.20liters.org/stats'

  def initialize
    response = HTTParty.get('https://track.20liters.org/stats')

    @as_of_date = Date.parse response.parsed_response.pop['as_of_date']

    @stat_ary = response.parsed_response.compact.map(&:symbolize_keys)
  end
end
