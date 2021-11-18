# frozen_string_literal: true

FactoryBot.define do
  factory :assembly do
    combination factory: :component
    item factory: :part
    quantity { Random.rand(1..4) }
  end

  factory :assembly_tech, class: Assembly do
    combination factory: :technology
    item factory: :component
    quantity { Random.rand(1..4) }
  end

  factory :assembly_comps, class: Assembly do
    combination factory: :component
    item factory: :component
    quantity { Random.rand(1..4) }
  end

  factory :assembly_tech_part, class: Assembly do
    combination factory: :technology
    item factory: :part
    quantity { Random.rand(1..4) }
  end

  # factory :assembly_tech_part_from_material, class: Assembly do
  #   combination factory: :technology
  #   item factory: :part_from_material
  #   quantity { Random.rand(1..4) }
  # end
end
