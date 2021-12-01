# frozen_string_literal: true

FactoryBot.define do
  factory :email do
    oauth_user
    from { ['chip@20liters.org'] }
    to { [Faker::Internet.unique.email] }
    subject { 'FactoryBot email sent by me' }
    datetime { Time.now }
    body { "FactoryBot wrote this email to me in latin: #{Faker::Lorem.paragraph(sentence_count: 30)}" }
    snippet { 'FactoryBot snippet text' }
    gmail_id { Faker::Alphanumeric.unique.alphanumeric(number: 10) }
    message_id { "#{Faker::Alphanumeric.unique.alphanumeric(number: 15)}@email.com" }
  end

  factory :email_to, class: Email do
    oauth_user
    from { [Faker::Internet.unique.email] }
    to { ['chip@20liters.org'] }
    subject { 'FactoryBot email sent to me' }
    datetime { Time.now }
    body { "FactoryBot wrote this email to me in latin: #{Faker::Lorem.paragraph(sentence_count: 20)}" }
    snippet { 'FactoryBot snippet text' }
    gmail_id { Faker::Alphanumeric.unique.alphanumeric(number: 10) }
    message_id { "#{Faker::Alphanumeric.unique.alphanumeric(number: 15)}@email.com" }
  end
end
