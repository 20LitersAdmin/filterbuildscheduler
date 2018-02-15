FactoryBot.define do
  factory :user do
    fname { Faker::Name.first_name }
    lname  { Faker::Name.last_name }
    email { Faker::Internet.email }
  end

  factory :leader, class: User do
    fname { Faker::Name.first_name }
    lname  { Faker::Name.last_name }
    email { Faker::Internet.email }
    is_leader true
  end

  factory :admin, class: User do
    fname { Faker::Name.first_name }
    lname  { Faker::Name.last_name }
    email { Faker::Internet.email }
    is_admin true
  end

  factory :user_w_password, class: User do
    fname { Faker::Name.first_name }
    lname  { Faker::Name.last_name }
    email { Faker::Internet.email }
    password "password"
    password_confirmation "password"
  end
end
