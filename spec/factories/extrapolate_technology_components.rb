FactoryBot.define do
  factory :tech_comp, class: ExtrapolateTechnologyComponent do
    component
    technology
    components_per_technology Random.rand(1..3)
    required [true, false].sample
  end
end