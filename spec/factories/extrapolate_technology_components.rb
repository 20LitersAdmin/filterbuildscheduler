FactoryBot.define do
  factory :tech_comp, class: ExtrapolateTechnologyComponent do
    component
    technology
    components_per_technology 1
  end
end