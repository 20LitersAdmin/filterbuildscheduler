# frozen_string_literal: true

class StripeCharge
  include ActiveModel::Model

  attr_accessor :from_causevox,
                :transaction_time,
                :stripe_charge_id,
                :amount_in_cents,
                :currency,
                :transaction_note,
                :transaction_type,
                :card_type,
                :first_name,
                :last_name,
                :email,
                :addr1,
                :addr2,
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
    @stripe_charge_id = charge[:id]
    @amount_in_cents = charge[:amount_captured]
    @currency = charge[:currency]
    @transaction_note = metadata[:cv_campaign_title]
    @transaction_type = payment_details[:funding]
    @card_type = payment_details.dig(:card, :brand)
    @first_name, @last_name = metadata[:cv_name].split
    @email = metadata[:cv_email]
    @addr1 = metadata[:cv_postal_line1]
    @addr2 = metadata[:cv_postal_line2]
    @city = metadata[:cv_postal_city]
    @state = metadata[:cv_postal_state]
    @postal = metadata[:cv_postal_zipcode]
    @country = metadata[:cv_postal_country]
  end
end
