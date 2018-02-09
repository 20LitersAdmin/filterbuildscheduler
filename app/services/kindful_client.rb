class KindfulClient
  include HTTParty
  if Rails.env.production?
    base_uri "https://app.kindful.com/api/v1"
  else
    base_uri "https://app-sandbox.kindful.com/api/v1"
  end

  def import_user(user)
    body_args = {
      id: user.id,
      fname: user.fname,
      lname: user.lname,
      email: user.email,
      email_opt_in: user.email_opt_out ? false : true
    }
    self.class.post("/imports", {headers: headers, body: contact(**body_args).to_json} )
  end

  def import_transaction(transaction)
    self.class.post("/imports", { headers: headers, body: contact_w_transaction(transaction).to_json } )
  end

  def token
    ENV.fetch("KF_FILTERBUILD_TOKEN")
  end

  def headers
    { 
      "Content-Type": "application/json",
      "Authorization": "Token token=\"#{token}\""
    }
  end

  def contact(id:, fname:, lname:, email:, email_opt_in:)
    {
      "data_format": "contact",
      "action_type": "update",
      "data_type": "json",
      "match_by": {
        "contact": "first_name_last_name_email",
        "group": "name"
      },
      "groups": ["Volunteer: Filter Builders"],
      "data": [
        {
          "id": id.to_s,
          "first_name": fname,
          "last_name": lname,
          "email": email,
          "email_opt_in": email_opt_in,
          "Volunteer: Filter Builders": "yes"
        }
      ]
    }
  end

  def contact_w_transaction(opts)
    # opts[:key] is symbolized already, just make sure the names match the charge_succeded_spec keys

    {
      "data_format": "contact_with_transaction",
      "action_type": "create",
      "data_type": "json",
      "match_by": {
        "contact": "first_name_last_name_email",
        "campaign": "name",
        "fund": "name"
      },
      "data": [
        {
          "first_name": opts[:metadata][:first_name],
          "last_name": opts[:metadata][:last_name],
          "email": opts[:metadata][:email],
          "addr1": opts[:metadata][:line1],
          "addr2": opts[:metadata][:line2],
          "city": opts[:metadata][:city],
          "state": opts[:metadata][:state],
          "postal": opts[:metadata][:zipcode],
          "country": opts[:metadata][:country],
          "amount_in_cents": opts[:amount],
          "currency": "usd",
          "campaign": "CauseVox Transactions",
          "fund": "Special Events 40400",
          "acknowledged": "false",
          "transaction_note": opts[:metadata][:campaign_name],
          "stripe_charge_id": opts[:id],
          "transaction_type": "Credit",
          "card_type": opts[:source][:brand],
         } 
      ]
    }

  end

end