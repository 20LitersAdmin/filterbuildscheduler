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
  end
end
