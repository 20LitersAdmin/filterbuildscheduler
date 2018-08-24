# frozen_string_literal: true

FactoryBot.define do
  factory :tech_part, class: ExtrapolateTechnologyPart do
    part
    technology
    parts_per_technology { Random.rand(1..3) }
    required { [true, false].sample }
  end
end
