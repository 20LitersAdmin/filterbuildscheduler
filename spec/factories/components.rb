FactoryBot.define do
  factory :component do
    name { Faker::Beer.name }
    quantity_per_box 1
  end

  factory :component_ct, class: Component do
    name { Faker::Beer.name }
    completed_tech true
    quantity_per_box 125
  end
end