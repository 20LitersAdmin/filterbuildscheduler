# frozen_string_literal: true

FactoryBot.define do
  factory :location do
    name { Faker::TvShows::TwinPeaks.unique.location }
    address1 { Faker::Address.street_address }
    address2 { Faker::Address.secondary_address }
    city { Faker::Address.city }
    state { Faker::Address.state }
    zip { Faker::Address.zip_code }
  end
end
