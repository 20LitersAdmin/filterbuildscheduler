# frozen_string_literal: true

FactoryBot.define do
  factory :event do
    title { Faker::Games::Zelda.unique.game }
    start_time { Faker::Time.forward(days: 20).beginning_of_day + 9.hours }
    end_time { start_time + 3.hours }
    min_leaders { 1 }
    max_leaders { 2 }
    min_registrations { 5 }
    max_registrations { 25 }
    technology
    location

    factory :recent_event do
      start_time { Faker::Time.backward(days: 2).beginning_of_day + 9.hours }
      end_time { start_time + 3.hours }
    end

    factory :past_event do
      start_time { Faker::Time.backward(days: 20).beginning_of_day + 9.hours }
      end_time { start_time + 3.hours }
    end

    factory :complete_event do
      start_time { Faker::Time.backward(days: 2).beginning_of_day + 9.hours }
      end_time { start_time + 3.hours }
      technologies_built { 30 }
      boxes_packed { 1 }
      attendance { 20 }
    end

    factory :event_upcoming do
      start_time { Faker::Time.forward(days: 1).beginning_of_day + 9.hours }
      end_time { start_time + 3.hours }
    end
  end
end
