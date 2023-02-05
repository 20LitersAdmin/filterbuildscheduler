# frozen_string_literal: true

class StripeCharge
  include ActiveModel::Model

  attr_accessor :from_causevox,
                :addr1,
                :addr2,
                :addr,
                :amount_in_cents,
                :amount_decimal,
                :charge,
                :city,
                :country,
                :email,
                :first_name,
                :last_name,
                :metadata,
                :payment_details,
                :postal,
                :state,
                :transaction_time,
                :transaction_date,
                :stripe_charge_id,
                :stripe_receipt_url,
                :transaction_note,
                :transaction_type

  # json = JSON.parse(File.read('spec/fixtures/files/charge_succeeded_spec.json'))
  def initialize(json)
    json.deep_symbolize_keys!
    @charge = json.dig(:data, :object)

    # [:application] code indicates CauseVox transaction
    # It is NOT a key or secret or security risk
    @from_causevox = @charge.present? && @charge[:application] == 'ca_14yEk8gp5dbBbYDnndXU9yTNM3Z3gyWS'

    return unless @from_causevox

    @metadata = @charge[:metadata]
    @payment_details = @charge[:payment_method_details]

    @addr1 =                  @metadata[:cv_postal_line1]
    @addr2 =                  @metadata[:cv_postal_line2]
    @addr =                   "#{@addr1} #{@addr2}".squish
    @amount_in_cents =        @charge[:amount_captured].to_i
    @amount_decimal =         @amount_in_cents / 100.0
    @city =                   @metadata[:cv_postal_city]
    @country =                @metadata[:cv_postal_country]
    @email =                  @metadata[:cv_email]
    @first_name, @last_name = @metadata[:cv_name].split
    @postal =                 @metadata[:cv_postal_zipcode]
    @state =                  @metadata[:cv_postal_state]
    @stripe_charge_id =       @charge[:id]
    @stripe_receipt_url =     @charge[:receipt_url]
    @transaction_time =       @charge[:created].to_i
    @transaction_date =       Time.at(@transaction_time).to_date.iso8601
    @transaction_note =       @metadata[:cv_campaign_title]
    @transaction_type =       @payment_details[:type]
  end

  def as_bloomerang_constituent
    {
      'Type': 'Individual',
      'Status': 'Active',
      'FirstName': @first_name,
      'LastName': @last_name,
      'PrimaryEmail': {
        'Type': 'Home',
        'Value': @email,
        'IsPrimary': true,
        'IsBad': false
      },
      'PrimaryAddress': {
        'Type': 'Home',
        'Street': @addr,
        'City': @city,
        'State': @state,
        'PostalCode': @postal,
        'Country': @country,
        'IsPrimary': true,
        'IsBad': false
      },
      'CustomValues': [
        {
          # 1992708 Attributes:  7785474 Current Donor
          'FieldId': 1992708,
          'ValueIds': [7785474]
        }
      ]
    }.as_json
  end

  def as_bloomerang_transaction(constituent_id)
    body = {
             'AccountId': constituent_id,
             'Date': @transaction_date,
             'Amount': @amount_decimal,
             # extra fields go here
             'Designations': [
               {
                 'Amount': @amount_decimal,
                 'Note': @transaction_note,
                 'AcknowledgementStatus': 'Yes',
                 'Type': 'Donation',
                 'NonDeductibleAmount': 0,
                 # 15364: Special Events 40400
                 'FundId': 15364,
                 # 16386: CauseVox Transactions
                 'CampaignId': 16386,
                 'AppealId': find_or_create_bloomerang_appeal,
                 'CustomValues': [
                   {
                     # Stripe Charge ID
                     'FieldId': 9346048,
                     'Value': @stripe_charge_id
                   },
                   {
                     # Stripe Receipt URL
                     'FieldId': 9347072,
                     'Value': @stripe_receipt_url
                   }
                 ]
               }
             ]
           }
    body.merge(payment_block).as_json
  end

  protected

  def find_or_create_bloomerang_appeal
    bloomerang_client = BloomerangClient.new(:causevoxsync)
    # Use @transaction_note to search for an appeal
    # returns active and inactive appeals
    results = bloomerang_client.search_for_appeal(@transaction_note)

    # create an appeal and use it if nothing was found
    return bloomerang_client.create_appeal(@transaction_note)['Id'] if results.empty?

    active = results.select { |a| a['IsActive'] == true }

    # take the first active appeal and use it
    return active[0]['Id'] if active.any?

    # take the first inactive appeal
    id = (results - active)[0]['Id']
    # re-activate the appeal
    bloomerang_client.set_appeal_to_active(id)
    id
  end

  def payment_block
    case @transaction_type
    when 'card', 'card_present'
      card_type =       @payment_details.dig(:card, :brand)
      card_last_four =  @payment_details.dig(:card, :last4)
      card_exp_month =  @payment_details.dig(:card, :exp_month)
      card_exp_year =   @payment_details.dig(:card, :exp_year)
      {
       'Method': 'CreditCard',
       'CreditCardType': card_type.upcase_first,
       'CreditCardLastFourDigits': card_last_four,
       'CreditCardExpMonth': card_exp_month,
       'CreditCardExpYear': card_exp_year
      }
    when 'ach_debit'
      eft_last_four =       @payment_details.dig(:ach_debit, :last4)
      eft_routing_number =  @payment_details.dig(:ach_debit, :routing_number)
      {
        'EftAccountType': 'Checking',
        'EftLastFourDigits': eft_last_four,
        'EftRoutingNumber': eft_routing_number
      }
    end
  end
end
