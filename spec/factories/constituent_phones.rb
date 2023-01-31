# frozen_string_literal: true

FactoryBot.define do
  factory :constituent_phone do
    constituent
    value { Faker::PhoneNumber.unique.phone_number }
    is_primary { true }
    phone_type { 'Home' }
  end
end
