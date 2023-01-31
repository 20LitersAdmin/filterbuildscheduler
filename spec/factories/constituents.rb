# frozen_string_literal: true

FactoryBot.define do
  factory :constituent do
    name { Faker::Name.unique.name }
    primary_email { Faker::Internet.unique.email }
    primary_phone { Faker::PhoneNumber.unique.phone_number }
  end
end
