# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LitersTrackerClient do
  let(:client) { LitersTrackerClient.new }
  let(:http_instance) { instance_double(HTTParty::Response) }
  let(:parsed_response) { JSON.parse(File.read("#{Rails.root}/spec/fixtures/files/liters_tracker_parsed_response_spec.json")) }

  it 'stores accessible variables' do
    expect(client.as_of_date.class).to eq Date
    expect(client.stat_ary.class).to eq Array
  end

  it 'calls HTTParty.get' do
    allow(HTTParty).to receive(:get).with('https://track.20liters.org/stats').and_return(http_instance)
    allow(http_instance).to receive(:parsed_response).and_return(parsed_response)

    expect(HTTParty).to receive(:get).with('https://track.20liters.org/stats')

    client
  end

  it 'sets the variables from the parsed_response' do
    allow(HTTParty).to receive(:get).with('https://track.20liters.org/stats').and_return(http_instance)
    allow(http_instance).to receive(:parsed_response).and_return(parsed_response)

    client

    expect(client.as_of_date.present?).to eq true
    expect(client.stat_ary.any?).to eq true
  end

  context 'when an error occurs' do
    it 'sets stat_ary to an empty array' do
      allow(HTTParty).to receive(:get).with('https://track.20liters.org/stats').and_raise(OpenSSL::SSL::SSLError.new)

      client

      expect(client.as_of_date.present?).to eq false
      expect(client.stat_ary.any?).to eq false
    end
  end
end
