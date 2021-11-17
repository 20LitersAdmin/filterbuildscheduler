# frozen_string_literal: true

FactoryBot.define do
  factory :assembly do
    combination { component }
    item { part }
    quantity { Random.rand(0..3) }
  end

  factory :assembly_tech, class: Assembly do
    combination { technology }
    item { component }
    quantity { Random.rand(0..3) }
  end

  factory :assembly_comps, class: Assembly do
    combination { component }
    item { component }
    quantity { Random.rand(0..3) }
  end

  factory :assembly_tech_part, class: Assembly do
    combination { technology }
    item { part }
    quantity { Random.rand(0..3) }
  end
end
