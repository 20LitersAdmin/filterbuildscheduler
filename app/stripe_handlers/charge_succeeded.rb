class ChargeSucceeded
  require 'json'
  require 'dotenv/load'
  require 'rest-client'

  @kf_url = ENV['KF_URL_TEST']
  @kf_causevox = ENV['KF_CAUSEVOX_TEST']
  
  def call(event)
    # Did the event come from CauseVox?
    #if event.data.object.application == 'ca_14yEk8gp5dbBbYDnndXU9yTNM3Z3gyWS'
      # get the metadata
      @create_date = event.created
      @strip_id = event.data.object.id

      @fname = event.data.object.currency
      @lname = event.data.object.description
      @email = event.data.object.outcome.network_status
      @amt = event.data.object.amount
      @addr1 = event.data.object.outcome.risk_level
      @addr2 = event.data.object.outcome.seller_message if event.data.object.outcome.seller_message
      @city = event.data.object.outcome.type
      @state = "MI"
      @zip = event.data.object.source.address_zip
      @country = event.data.object.source.zip if event.data.object.source.zip
      @campaign = event.data.object.description

      # @fname = event.data.object.metadata.first_name
      # @lname = event.data.object.metadata.last_name
      # @email = event.data.object.metadata.email
      # @amt = event.data.object.metadata.amount
      # @addr1 = event.data.object.metadata.line1
      # @addr2 = event.data.object.metadata.line2 if event.data.object.metadata.line2
      # @city = event.data.object.metadata.city
      # @state = event.data.object.metadata.state
      # @zip = event.data.object.metadata.zipcode
      # @country = event.data.object.metadata.country if event.data.object.metadata.country
      # @campaign = event.data.object.metadata.campaign_name
      # make json:
      @json = {
        data_format: "contact_with_transaction",
        action_type: "update",
        match_by: {
          contact: "first_name_last_name_email"
        },
        data_type: "json",
          data: 
            [{
              first_name: @fname,
              last_name: @lname,
              email: @email,
              addr1: @addr1,
              addr2: @addr2,
              city: @city,
              state: @state,
              postal: @zip,
              country: @country,
              created_at: @create_date,
              amount_in_cents: @amt,
              currency: "usd",
              transaction_time: @create_date,
              campaign_id: "270572",
              fund_id: "27452",
              acknowledged: "false",
              transaction_note: "CauseVox #{@campaign}",
              stripe_charge_id: @stripe_id,
              transaction_type: "Credit",
              was_refunded: "false",
              non_tax_deductible_amount_in_cents: "0",
              is_donation: "true",
            }]
      }
      #now send it all to Kindful contact_with_transaction type:update match_by = first_name_last_name_email
      RestClient.log=STDOUT # Optionally turn on logging
      # RestClient::Request.execute(
      #   method: :post,
      #   url: "#{ @kf_url }/imports",
      #   payload: @json.as_json,
      #   headers: @kf_causevox
      #   )
      RestClient.post @kf_url, "#{@json.as_json}", {content_type: :json, accept: :json}
    #end
  end

end