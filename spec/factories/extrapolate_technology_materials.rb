FactoryBot.define do
  factory :tech_mat, class: ExtrapolateTechnologyMaterial do
    material
    technology
    materials_per_technology { Random.rand(1..3) }
    required [true, false].sample
  end
end