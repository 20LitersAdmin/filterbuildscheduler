class KindfulCausevox
  require 'json'

  @kf_url = ENV['KF_URL_TEST']
  @kf_causevox = ENV['KF_CAUSEVOX_TEST']

  def initialize(data, create_date, stripe_id)
    # @fname = data.first_name
    # @lname = data.last_name
    # @email = data.email
    # @amt = data.amount
    # @addr1 = data.line1
    # @addr2 ||= data.line2
    # @city = data.city
    # @state = data.state
    # @zip = data.zipcode
    # @country ||= data.country
    # @create_date = create_date
    # @campaign = data.campaign_name
    # @stripe_id = stripe_id
    # # make json:
    # @json = {
    #   "data_format": "contact_with_transaction",
    #   "action_type":"update",
    #   "match_by": {
    #     "contact": "first_name_last_name_email"
    #   },
    #   "data_type":"json",
    #     "data": 
    #       [{
    #         "first_name": @fname,
    #         "last_name": @lname,
    #         "email": @email,
    #         "addr1": @addr1,
    #         "addr2": @addr2,
    #         "city": @city,
    #         "state": @state,
    #         "postal": @zip,
    #         "country": @country,
    #         "created_at": @create_date,
    #         "amount_in_cents": @amt,
    #         "currency": "usd",
    #         "transaction_time": @create_date,
    #         "campaign_id": "270572",
    #         "fund_id": "27452",
    #         "acknowledged": "false",
    #         "transaction_note": "CauseVox #{@campaign}",
    #         "stripe_charge_id": @stripe_id,
    #         "transaction_type": "Credit",
    #         "was_refunded": "false",
    #         "non_tax_deductible_amount_in_cents": "0",
    #         "is_donation": "true",
    #       }]
    # }
    # RestClient.post "#{@kf_url}/import", { id: @kf_causevox, body: @json }
  end

end