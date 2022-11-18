# frozen_string_literal: true

# =====> Hello, Interviewers!
# This was the first time I ever worked with webhooks and APIs.
# Ross Hunter agreed to freelance this project for us under the condition
# that he teach me to do it instead of doing it himself.
#
# Business case: One of our donation systems doesn't integrate with our
# donor CRM. Meaning donor and gift records from that system had to be
# manually added to the donor CRM.
#
# But, when a gift is made in that donation system, it is sent
# to Stripe as the payment gateway, which can issue the event info to
# a webhook.
# And our donor CRM has an API I can use to generate donor and donation
# records.
#
# Zapier wanted money, so we decided to reinvent this wheel.
#
# It didn't seem worth it to spin up a whole new app just to host one
# endpoint for the one use case, so the event registration & inventory app
# became an event registration & inventory & donations from stripe
# processing app. And the monolith was born.
class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def stripe
    # Stripe's test webhook doesn't have application or metadata.
    # To test to Kindful's sandbox, we need to send the charge_succeeded_spec file.
    # So, when in Development and the webhook is received from Stripe, ignore it and use my test file
    json =
      if Rails.env.development?
        JSON.parse(File.read("#{Rails.root}/spec/fixtures/files/charge_succeeded_spec.json"))
      else # test and production envs
        params.as_json
      end

    charge = StripeCharge.new(json)

    KindfulClient.new.import_transaction(charge) if charge.from_causevox

    head :ok
  end
end
