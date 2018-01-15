FactoryBot.define do
  factory :count_comp, class: Count do
    inventory
    component
    loose_count Random.rand(0..130)
    unopened_boxes_count Random.rand(0..30)
  end

  factory :count_part, class: Count do
    inventory
    part
    loose_count Random.rand(6..130)
    unopened_boxes_count Random.rand(6..30)
  end

  factory :count_mat, class: Count do
    inventory
    material
    loose_count Random.rand(0..130)
    unopened_boxes_count Random.rand(0..30)
  end
end