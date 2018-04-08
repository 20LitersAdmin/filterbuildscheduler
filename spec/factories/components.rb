FactoryBot.define do
  factory :component do
    name { Faker::Beer.name }
    quantity_per_box 1
  end

  factory :component_ct, class: Component do
    name { Faker::Beer.name }
    completed_tech true
    quantity_per_box { Random.rand(1..5) }
  end
end