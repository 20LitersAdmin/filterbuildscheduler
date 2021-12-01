# frozen_string_literal: true

FactoryBot.define do
  factory :registration do
    user
    event
    attended { false }
    guests_registered { Random.rand(0..5) }

    factory :registration_attended do
      attended { true }
      guests_attended { Random.rand(0..5) }
    end

    factory :registration_leader do
      leader { true }
    end

    factory :registration_leader_attended do
      attended { true }
      leader { true }
      guests_attended { Random.rand(0..5) }
    end
  end
end
