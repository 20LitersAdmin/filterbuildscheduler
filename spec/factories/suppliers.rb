# frozen_string_literal: true

FactoryBot.define do
  factory :supplier do
    name { Faker::Company.name}
    url { Faker::Internet.url }
    email { Faker::Internet.safe_email }
    poc_name { Faker::DrWho.character }
    poc_email { Faker::Internet.safe_email }
    comments { Faker::Company.catch_phrase }
  end
end
