# frozen_string_literal: true

FactoryBot.define do
  factory :email do
    oauth_user_id { 1 }
    from { ['chip@20liters.org'] }
    to { [Faker::Internet.unique.email] }
    subject { 'FactoryBot email subject' }
    datetime { Time.now }
    body { 'FactoryBot created this email for the purposes of writing tests' }
    snippet { 'FactoryBot snippet text' }
    gmail_id { Faker::Alphanumeric.unique.alphanumeric(number: 10) }
    message_id { "#{Faker::Alphanumeric.unique.alphanumeric(number: 15)}@email.com" }
  end
end
