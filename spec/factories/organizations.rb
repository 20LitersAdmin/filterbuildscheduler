# frozen_string_literal: true

FactoryBot.define do
  factory :organization do
    company_name { Faker::Company.unique.name }
    email { Faker::Internet.unique.email }
  end
end
