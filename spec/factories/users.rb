# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    fname { Faker::Name.unique.first_name }
    lname { Faker::Name.unique.last_name }
    email { Faker::Internet.unique.email }

    factory :leader do
      is_leader { true }
    end

    factory :admin do
      is_admin { true }
    end

    factory :user_w_password do
      password { 'password' }
      password_confirmation { 'password' }
    end

    factory :scheduler do
      is_scheduler { true }
    end

    factory :setup_crew do
      is_setup_crew { true }
    end

    factory :data_manager do
      is_data_manager { true }
    end

    factory :oauth_admin do
      is_oauth_admin { true }
    end

    factory :inventoryist do
      does_inventory { true }
    end
  end
end
