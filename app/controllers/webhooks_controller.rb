class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def receive
    # Stripe's test webhook doesn't have application or metadata.
    # To test to Kindful's sandbox, we need to send the charge_succeeded_spec file.
    # So, when in Development and the webhook is received from Stripe, ignore it and use my test file
    if Rails.env.development?
      file = JSON.parse(File.read("#{Rails.root}/spec/fixtures/files/charge_succeeded_spec.json"))
      @json = file["data"]["object"]
    else # test and production envs
      @json = params[:data][:object].as_json
    end

    @json.deep_symbolize_keys!

    if @json[:application] == "ca_14yEk8gp5dbBbYDnndXU9yTNM3Z3gyWS"
      KindfulClient.new.import_transaction(@json)
    end

    head :ok
  end

end
