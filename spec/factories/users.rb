FactoryBot.define do
  factory :user do
    fname { Faker::Name.first_name }
    lname  { Faker::Name.last_name }
    email { Faker::Internet.email }
  end
end
