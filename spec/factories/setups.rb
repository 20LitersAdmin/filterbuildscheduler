# frozen_string_literal: true

FactoryBot.define do
  factory :setup do
    event
    creator factory: :setup_crew
    date { event.start_time - 2.days }

    factory :setup_in_past do
      date { Faker::Time.between_dates(from: Time.now - 2.days, to: Time.now - 1.day, period: :morning) }
    end

    factory :setup_day_of do
      date { event.start_time - 2.hours }
    end

    factory :setup_with_users do
      users { build_list(:setup_crew, 2) }
    end

    factory :setup_with_reminder do
      date { Faker::Time.between_dates(from: Time.now - 2.days, to: Time.now - 1.day, period: :morning) }
      reminder_sent_at { date - 2.days }
    end
  end
end
