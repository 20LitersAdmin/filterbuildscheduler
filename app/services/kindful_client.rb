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
      phone: user.phone,
      email_opt_in: user.email_opt_out ? false : true
    }
    self.class.post("/imports", {headers: headers, body: contact(**body_args).to_json} )
  end

  def import_transaction
    #causevox
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

  def contact_w_transaction()
    #causevox
  end

  def contact(id:, fname:, lname:, email:, phone:, email_opt_in:)
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