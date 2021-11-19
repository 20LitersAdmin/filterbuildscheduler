# frozen_string_literal: true

FactoryBot.define do
  factory :count do
    inventory
    item factory: :part
    loose_count { Random.rand(6..130) }
    unopened_boxes_count { Random.rand(6..30) }
  end

  factory :count_comp, class: Count do
    inventory
    item factory: :component
    loose_count { Random.rand(0..130) }
    unopened_boxes_count { Random.rand(0..30) }
  end

  factory :count_part, class: Count do
    inventory
    item factory: :part
    loose_count { Random.rand(6..130) }
    unopened_boxes_count { Random.rand(6..30) }
  end

  factory :count_mat, class: Count do
    inventory
    item factory: :material
    loose_count { Random.rand(0..130) }
    unopened_boxes_count { Random.rand(0..30) }
  end

  factory :count_submitted, class: Count do
    inventory
    user
    item factory: :part
    loose_count { Random.rand(6..130) }
    unopened_boxes_count { Random.rand(6..30) }
  end
end
