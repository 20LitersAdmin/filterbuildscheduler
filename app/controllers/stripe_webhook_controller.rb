class StripeWebhookController < ApplicationController

  def receive
    @json = params[:object]
    # might need to symbolize / deep symbolize this

    # first check for the application
    if @json[:application] == "ca_14yEk8gp5dbBbYDnndXU9yTNM3Z3gyWS"
      KindfulClient.new.import_transaction(@json)
    end

    head :ok
    # check the secret key against STRIPE_WHSEC
  end
end