FactoryBot.define do
  factory :supplier do
    name { Faker::Company.name}
    url { Faker::Internet.url }
    email { Faker::Internet.safe_email }
    POC_name { Faker::DrWho.character }
    POC_email { Faker::Internet.safe_email }
    comments { Faker::Company.catch_phrase }
  end
end