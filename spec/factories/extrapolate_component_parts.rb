FactoryBot.define do
  factory :comp_part, class: ExtrapolateComponentPart do
    component
    part
    parts_per_component { Random.rand(1..5) }
  end
end