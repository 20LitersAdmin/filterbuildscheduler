# frozen_string_literal: true

class StripeCharge
  include ActiveModel::Model

  attr_accessor :from_causevox,
                :transaction_time,
                :transaction_date,
                :stripe_charge_id,
                :stripe_receipt_url,
                :amount_in_cents,
                :amount_decimal,
                # :currency,
                :transaction_note,
                # :transaction_type,
                :card_type,
                :card_last_four,
                :card_exp_month,
                :card_exp_year,
                :first_name,
                :last_name,
                :email,
                :addr1,
                :addr2,
                :addr,
                :city,
                :state,
                :postal,
                :country

  def initialize(json)
    json.deep_symbolize_keys!
    charge = json.dig(:data, :object)

    # [:application] code indicates CauseVox transaction
    # It is NOT a key or secret or security risk
    @from_causevox = charge.present? && charge[:application] == 'ca_14yEk8gp5dbBbYDnndXU9yTNM3Z3gyWS'

    return unless @from_causevox

    metadata = charge[:metadata]
    payment_details = charge[:payment_method_details]

    @transaction_time = charge[:created]
    @transaction_date = Time.at(@transaction_time).to_date.iso8601
    @stripe_charge_id = charge[:id]
    @stripe_receipt_url = charge[:receipt_url]
    @amount_in_cents = charge[:amount_captured]
    @amount_decimal = @amount_in_cents / 100.0
    # @currency = charge[:currency]
    @transaction_note = metadata[:cv_campaign_title]
    # TODO: if CauseVox accepts ACH, this equates to EFT fields
    # @transaction_type = payment_details[:type]
    @card_type = payment_details.dig(:card, :brand)
    @card_last_four = payment_details.dig(:card, :last4)
    @card_exp_month = payment_details.dig(:card, :exp_month)
    @card_exp_year = payment_details.dig(:card, :exp_year)
    @first_name, @last_name = metadata[:cv_name].split
    @email = metadata[:cv_email]
    @addr1 = metadata[:cv_postal_line1]
    @addr2 = metadata[:cv_postal_line2]
    @addr = "#{@addr1} #{@addr2}".squish
    @city = metadata[:cv_postal_city]
    @state = metadata[:cv_postal_state]
    @postal = metadata[:cv_postal_zipcode]
    @country = metadata[:cv_postal_country]
  end

  def as_bloomerang_constituent
    # TODO: leaving PrimaryEmail:AccountID && PrimaryAddress:AccountID blank, assuming it will get assigned
    {
      'Type': 'Individual',
      'Status': 'Active',
      'FirstName': @first_name,
      'LastName': @last_name,
      # 'InformalName': 'string', # TODO: ask Amanda
      # 'FormalName': 'string', # TODO: ask Amanda
      # 'EnvelopeName': 'string', # TODO: ask Amanda
      # 'RecognitionName': 'string', # TODO: ask Amanda
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
      }
      # TODO: ask Amanda, see below
      # 'CustomValues': [
      #   {
      #     # 1995779: Event Participation History
      #     'FieldId': 1995779,
      #     'ValueIds': [
      #       0
      #     ]
      #   }
      # ]
    }

    ### CustomValues issue:
    # https://crm.bloomerang.co/Settings/Constituent/CustomField/Edit/1995779
    # The CustomField is set to PickMultiple, so we're restricted to existing list items
    # Meaning every CauseVox campaign would need to be added to the list
    # And I'd need to pull every CustomValue to try to find one in Bloomerang that matches what is coming from CauseVox
    #
    ## Category: Additional Donor Information
    # {"Id"=>18432, "Name"=>"Additional Donor Information", "SortIndex"=>0}
    #
    ## CustomField: Event Participation History
    # {"Id"=>1995779,
    #   "CategoryId"=>18432,
    #   "Name"=>"Event Participation History",
    #   "SortIndex"=>2,
    #   "IsRequired"=>false,
    #   "IsActive"=>true,
    #   "DataType"=>"Text",
    #   "PickType"=>"PickMultiple"}
    #
    ## CustomValues for: Event Participation History
    # [{"Id"=>1993743, "FieldId"=>1995779, "Value"=>"50 for 50", "IsActive"=>true},
    #  {"Id"=>1993740, "FieldId"=>1995779, "Value"=>"Running Challenge", "IsActive"=>true},
    #  {"Id"=>1993744, "FieldId"=>1995779, "Value"=>"Townley Family Bake Sale", "IsActive"=>true},
    #  {"Id"=>1993739, "FieldId"=>1995779, "Value"=>"W4W Cove Run", "IsActive"=>true},
    #  {"Id"=>1993741, "FieldId"=>1995779, "Value"=>"W4W Forest Hills Central", "IsActive"=>true},
    #  {"Id"=>1994765, "FieldId"=>1995779, "Value"=>"W4W Hudsonville", "IsActive"=>true},
    #  {"Id"=>1994770, "FieldId"=>1995779, "Value"=>"W4W Mars Hill", "IsActive"=>true},
    #  {"Id"=>1994766, "FieldId"=>1995779, "Value"=>"W4W Paseo del Rey", "IsActive"=>true},
    #  {"Id"=>1994771, "FieldId"=>1995779, "Value"=>"W4W Rosewood", "IsActive"=>true},
    #  {"Id"=>1993738, "FieldId"=>1995779, "Value"=>"W4W Zeeland", "IsActive"=>true},
    #  {"Id"=>1994767, "FieldId"=>1995779, "Value"=>"World Water Day", "IsActive"=>true},
    #  {"Id"=>1993742, "FieldId"=>1995779, "Value"=>"Z-Connect Campaign", "IsActive"=>true}]
  end

  def as_bloomerang_transaction(constituent_id)
    {
      'AccountId': constituent_id,
      'Date': @transaction_date,
      'Amount': @amount_decimal,
      'Method': 'CreditCard',
      'CreditCardType': @card_type.upcase_first,
      'CreditCardLastFourDigits': @card_last_four,
      'CreditCardExpMonth': @card_exp_month,
      'CreditCardExpYear': @card_exp_year,
      # TODO: could CauseVox be ACH?
      # https://stripe.com/docs/api/charges/object#charge_object-payment_method_details-ach_debit
      # "EftAccountType": "Checking",
      # "EftLastFourDigits": "string",
      # "EftRoutingNumber": "string",
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
  end
end
