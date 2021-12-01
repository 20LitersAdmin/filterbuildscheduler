# frozen_string_literal: true

FactoryBot.define do
  factory :replicator do
    frequency { 'monthly' }
    occurrences { 3 }
    replicate_leaders { false }
    association :user, factory: :admin
  end
end
