FactoryBot.define do
  factory :tech_part, class: ExtrapolateTechnologyPart do
    part
    technology
    parts_per_technology 1
  end
end