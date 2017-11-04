FactoryBot.define do
  factory :location do
    name { Faker::TwinPeaks.location }
    address1 { Faker::Address.street_address }
    address2 { Faker::Address.secondary_address }
    city { Faker::Address.city }
    state { Faker::Address.state }
    zip { Faker::Address.zip_code }
  end
end
