# frozen_string_literal: true

FactoryBot.define do
  factory :constituent_email do
    value { Faker::Internet.unique.email }
    constituent
    is_primary { true }
    email_type { 'Home' }
  end
end
