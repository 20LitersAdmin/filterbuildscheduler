# frozen_string_literal: true

FactoryBot.define do
  factory :count do
    inventory
    item factory: :part
    loose_count { Random.rand(6..130) }
    unopened_boxes_count { Random.rand(6..30) }

    factory :count_tech do
      item factory: :technology
    end

    factory :count_comp do
      item factory: :component
    end

    factory :count_mat do
      item factory: :material
    end

    factory :count_submitted do
      user
    end
  end
end
