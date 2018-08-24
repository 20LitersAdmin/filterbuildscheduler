# frozen_string_literal: true

FactoryBot.define do
  factory :technology do
    name { Faker::Beer.name }
    description { Faker::TwinPeaks.quote }
    ideal_build_length { 2 }
    ideal_group_size { 20 }
    ideal_leaders { 2 }
    family_friendly { true }
    unit_rate { 1 }
    owner { "No one!" }
    people { 5 }
    lifespan_in_years { 10 }
    liters_per_day { 100 }
  end
end
