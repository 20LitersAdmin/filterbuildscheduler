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
    charge = StripeCharge.new(params.as_json)

    BloomerangClient.new(:causevoxsync).create_from_causevox(charge) if charge.from_causevox

    head :ok
  end
end
