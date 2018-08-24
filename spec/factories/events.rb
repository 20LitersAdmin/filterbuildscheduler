# frozen_string_literal: true

FactoryBot.define do
  factory :event do
    title { Faker::Zelda.game }
    start_time { Faker::Time.forward(90) }
    end_time { start_time + 3.hours }
    min_leaders { 1 }
    max_leaders { 2 }
    min_registrations { 5 }
    max_registrations { 25 }
    technology
    location
  end

  factory :recent_event, class: Event do
    title { Faker::Zelda.game}
    start_time { Faker::Time.backward(5) }
    end_time { start_time + 3.hours }
    min_leaders { 1 }
    max_leaders { 2 }
    min_registrations { 5 }
    max_registrations { 25 }
    technology
    location
  end

  factory :past_event, class: Event do
    title { Faker::Zelda.game}
    start_time { Faker::Time.backward(90) }
    end_time { start_time + 3.hours }
    min_leaders { 1 }
    max_leaders { 2 }
    min_registrations { 5 }
    max_registrations { 25 }
    technology
    location
  end

  factory :complete_event, class: Event do
    title { Faker::Zelda.game }
    start_time { Time.now - 4.hours }
    end_time { start_time + 3.hours }
    min_leaders { 1 }
    max_leaders { 2 }
    min_registrations { 5 }
    max_registrations { 25 }
    technology
    location
    technologies_built { 30 }
    boxes_packed { 1 }
    attendance { 20 }
  end
end
