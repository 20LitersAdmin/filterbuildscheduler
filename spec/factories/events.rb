FactoryBot.define do
  factory :event do
    title { Faker::TwinPeaks.quote }
    start_time { Faker::Time.backward(30) }
    end_time { start_time + 3.hours }
    min_leaders 1
    max_leaders 2
    min_registrations 5
    max_registrations 25
    technology
    location
  end
end
