# frozen_string_literal: true

FactoryBot.define do
  factory :event do
    title { Faker::Games::Zelda.unique.game }
    start_time { Faker::Time.between_dates(from: Time.now + 10.days, to: Time.now + 20.days, period: :morning) }
    end_time { start_time + 2.hours }
    min_leaders { 1 }
    max_leaders { 2 }
    min_registrations { 5 }
    max_registrations { 25 }
    technology
    location

    factory :recent_event do
      start_time { Faker::Time.between_dates(from: Time.now - 4.days, to: Time.now - 2.days, period: :afternoon) }
      end_time { start_time + 3.hours }
    end

    factory :past_event do
      start_time { Faker::Time.between_dates(from: Time.now - 25.days, to: Time.now - 15.days, period: :afternoon) }
      end_time { start_time + 3.hours }
    end

    factory :complete_event_technology do
      start_time { Faker::Time.between_dates(from: Time.now - 4.days, to: Time.now - 2.days, period: :afternoon) }
      end_time { start_time + 3.hours }
      technologies_built { 30 }
      boxes_packed { 1 }
      attendance { 20 }
    end

    factory :complete_event_impact do
      start_time { Faker::Time.between_dates(from: Time.now - 4.days, to: Time.now - 2.days, period: :afternoon) }
      end_time { start_time + 3.hours }
      impact_results { 30 }
      attendance { 20 }
    end

    factory :event_upcoming do
      start_time { Faker::Time.between_dates(from: Time.now + 2.days, to: Time.now + 4.days, period: :afternoon) }
      end_time { start_time + 3.hours }
    end
  end
end
