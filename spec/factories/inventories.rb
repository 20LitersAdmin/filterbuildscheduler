# frozen_string_literal: true

FactoryBot.define do
  factory :inventory do
    manual { true }
    date { Date.today }

    factory :inventory_ship do
      manual { false }
      shipping { true }
    end

    factory :inventory_rec do
      manual { false }
      receiving { true }
    end

    factory :inventory_event do
      manual { false }
      event factory: :complete_event_technology
    end
  end
end
