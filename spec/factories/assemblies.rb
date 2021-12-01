# frozen_string_literal: true

FactoryBot.define do
  factory :assembly do
    combination factory: :component
    item factory: :part
    quantity { Random.rand(1..4) }

    factory :assembly_tech do
      combination factory: :technology
      item factory: :component
    end

    factory :assembly_comps do
      item factory: :component
    end

    factory :assembly_tech_part do
      combination factory: :technology
      item factory: :part
    end

    factory :assembly_part_from_material do
      item factory: :part_from_material
    end
  end
end
