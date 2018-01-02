class KindfulClient
  include HTTParty
  if Rails.env.production?
    base_uri "https://app.kindful.com/api/v1"
  else
    base_uri "https://app-sandbox.kindful.com/api/v1"
  end

  def update_user(user)
    body_args = {
      id: user.id,
      fname: user.fname,
      lname: user.lname,
      email: user.email,
      phone: user.phone
    }
    self.class.post("/imports", headers: headers, body: body(**body_args) )
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

  def body(id:, fname:, lname:, email:, phone:)
    {
      "data_format": "contact",
      "action_type": "update",
      "data_type": "json",
      "match_by": {
        "contact": "first_name_last_name_email"
      },
      "groups": ["Volunteer: Filter Builders"],
      "data": [
        {
          "external_id": id,
          "first_name": fname,
          "last_name": lname,
          "email": email,
          "primary_phone": phone,
          "Volunteer: Filter Builders": "yes"
        }
      ]
    }
  end

end