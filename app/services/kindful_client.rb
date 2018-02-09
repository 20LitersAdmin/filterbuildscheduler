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
          "first_name": opts[:first_name],
          "last_name": opts[:lname],
          "email": opts[:email],
          "addr1": opts[:line1],
          "addr2": opts[:line2],
          "city": opts[:city],
          "state": opts[:state],
          "postal": opts[:zipcode],
          "country": opts[:country],
          "amount_in_cents": opts[:amount_in_cents],
          "currency": "usd",
          "campaign": "CauseVox Transactions",
          "fund": "Special Events 40400",
          "acknowledged": "false",
          "transaction_note": opts[:campaign_name],
          "stripe_charge_id": opts[:charge_id],
          "transaction_type": opts[:funding],
          "card_type": opts[:card_brand],
         } 
      ]
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

end