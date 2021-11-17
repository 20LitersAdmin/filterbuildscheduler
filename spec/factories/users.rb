# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    fname { Faker::Name.unique.first_name }
    lname { Faker::Name.unique.last_name }
    email { Faker::Internet.unique.email }
    is_admin { false }
    is_leader { false }
  end

  factory :leader, class: User do
    fname { Faker::Name.unique.first_name }
    lname { Faker::Name.unique.last_name }
    email { Faker::Internet.unique.email }
    is_leader { true }
  end

  factory :admin, class: User do
    fname { Faker::Name.unique.first_name }
    lname { Faker::Name.unique.last_name }
    email { Faker::Internet.email }
    is_admin { true }
  end

  factory :user_w_password, class: User do
    fname { Faker::Name.unique.first_name }
    lname { Faker::Name.unique.last_name }
    email { Faker::Internet.email }
    password { 'password' }
    password_confirmation { 'password' }
  end

  factory :scheduler, class: User do
    fname { Faker::Name.unique.first_name }
    lname { Faker::Name.unique.last_name }
    email { Faker::Internet.email }
    is_scheduler { true }
  end

  factory :data_manager, class: User do
    fname { Faker::Name.unique.first_name }
    lname { Faker::Name.unique.last_name }
    email { Faker::Internet.email }
    is_data_manager { true }
  end

  factory :oauth_admin, class: User do
    fname { Faker::Name.unique.first_name }
    lname { Faker::Name.unique.last_name }
    email { Faker::Internet.email }
    is_oauth_admin { true }
  end

  factory :inventoryist, class: User do
    fname { Faker::Name.unique.first_name }
    lname { Faker::Name.unique.last_name }
    email { Faker::Internet.email }
    does_inventory { true }
  end
end
