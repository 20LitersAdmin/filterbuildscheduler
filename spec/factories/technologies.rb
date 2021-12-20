# frozen_string_literal: true

FactoryBot.define do
  factory :technology do
    name { Faker::Beer.name }
    short_name { name[0..4] }
    description { Faker::TvShows::TwinPeaks.quote }
    ideal_build_length { 2 }
    ideal_group_size { 20 }
    ideal_leaders { 2 }
    family_friendly { true }
    list_worthy { true }
    unit_rate { 1 }
    owner { Faker::Company.name }
    people { 5 }
    quantity_per_box { 30 }
    lifespan_in_years { 10 }
    liters_per_day { 100 }
  end
end
