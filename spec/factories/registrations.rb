FactoryBot.define do
  factory :registration do
    user
    event
    attended false
    guests_registered Random.rand(0..10)
  end

  factory :registration_attended, class: Registration do
    user
    event
    attended true
    guests_registered Random.rand(0..10)
    guests_attended Random.rand(0..10)
  end

  factory :registration_leader, class: Registration do
    user
    event
    leader true
    guests_registered Random.rand(0..3)
  end
end
