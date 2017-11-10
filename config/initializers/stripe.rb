require 'json'

Rails.configuration.stripe = {
  publishable_key: ENV['STRIPE_PK_TEST'],
  secret_key: ENV['STRIPE_SK_TEST'],
  signing_secret: ENV['STRIPE_WHSEC_TEST']
}

Stripe.api_key = Rails.configuration.stripe[:secret_key]
StripeEvent.signing_secret = Rails.configuration.stripe[:signing_secret]

StripeEvent.configure do |event|
  event.subscribe 'charge.succeeded', ChargeSucceeded.new
end