# frozen_string_literal: true

FactoryBot.define do
  factory :material_part, class: ExtrapolateMaterialPart do
    material
    part
    parts_per_material { Random.rand(1..5) }
  end
end
