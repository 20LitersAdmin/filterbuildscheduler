FactoryBot.define do
  factory :material do
    name { Faker::Beer.name }
    supplier
    quantity_per_box { Random.rand(1..340) }
    price_cents { Random.rand(200..9900) }
    minimum_on_hand { Random.rand(1..30) }
  end
end