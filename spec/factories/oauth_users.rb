# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_user do
    name { Faker::Name.unique.first_name }
    email { Faker::Internet.unique.email }
    oauth_id { Faker::Number.unique.number(digits: 20) }
    oauth_token { Faker::Alphanumeric.unique.alphanumeric(number: 120) }
    sync_emails { true }
  end
end
