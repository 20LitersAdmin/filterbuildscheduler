FactoryBot.define do
  factory :part do
    name { Faker::Beer.name }
    supplier
    price_cents Random.rand(7..2900)
    minimum_on_hand Random.rand(10..2000)
  end
end