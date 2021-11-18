# frozen_string_literal: true

FactoryBot.define do
  factory :component do
    name { Faker::Beer.name }
    quantity_per_box { 1 }
  end
end
