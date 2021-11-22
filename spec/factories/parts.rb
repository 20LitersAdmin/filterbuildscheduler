# frozen_string_literal: true

FactoryBot.define do
  factory :part do
    name { Faker::Beer.name }
    supplier
    price_cents { Random.rand(7..2900) }
    minimum_on_hand { Random.rand(10..2000) }
  end

  factory :part_from_material, class: Part do
    name { Faker::Beer.name }
    material
    quantity_from_material { 0.25 }
    minimum_on_hand { Random.rand(10..2000) }
  end
end
