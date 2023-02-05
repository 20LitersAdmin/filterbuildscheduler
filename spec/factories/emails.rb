# frozen_string_literal: true

FactoryBot.define do
  factory :email do
    transient do
      fake_email { Faker::Internet.unique.email }
      constituent { association :constituent, primary_email: fake_email }
    end

    oauth_user
    from { [oauth_user.email] }
    to { [fake_email] }
    subject { 'FactoryBot email sent by me' }
    datetime { Time.now }
    body { "FactoryBot wrote this email to me in latin: #{Faker::Lorem.paragraph(sentence_count: 30)}" }
    snippet { 'FactoryBot snippet text' }
    gmail_id { Faker::Alphanumeric.unique.alphanumeric(number: 10) }
    message_id { "#{Faker::Alphanumeric.unique.alphanumeric(number: 15)}@email.com" }
    matched_constituents { [constituent.id] }
  end

  factory :email_to, class: Email do
    transient do
      fake_email { Faker::Internet.unique.email }
      constituent { association :constituent, primary_email: fake_email }
    end

    oauth_user
    from { [fake_email] }
    to { [oauth_user.email] }
    subject { 'FactoryBot email sent to me' }
    datetime { Time.now }
    body { "FactoryBot wrote this email to me in latin: #{Faker::Lorem.paragraph(sentence_count: 20)}" }
    snippet { 'FactoryBot snippet text' }
    gmail_id { Faker::Alphanumeric.unique.alphanumeric(number: 10) }
    message_id { "#{Faker::Alphanumeric.unique.alphanumeric(number: 15)}@email.com" }
    matched_constituents { [constituent.id] }
  end
end
