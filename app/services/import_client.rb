class ImportClient
  include HTTParty

  # base_uri "https://app-sandbox.kindful.com/api/v1"
  base_uri "https://app.kindful.com/api/v1"

  ###### How to manually batch enter people into Kindful using this app:
  # Create a json file with fname, lname, email
  # in IRB console:
  # require "import_client"
  # set users = #Array
  # users.each do |user|
  #   ImportClient.new.import_user_w_note(user[:fname], user[:lname], user[:email])
  # end

  def import_user(fname, lname, email)
    body_args = {
      fname: fname,
      lname: lname,
      email: email
    }
    self.class.post("/imports", {headers: headers, body: contact(**body_args).to_json} )
    puts "processed for #{fname} #{lname}: #{response}"
  end

  def import_user_w_note(fname, lname, email)
    body_args = {
      fname: fname,
      lname: lname,
      email: email,
      note_time: Time.new(2018,5,19,11).iso8601,
      note_subject: "Attended W4W Zeeland 2018",
    }
    response = self.class.post("/imports", {headers: headers, body: contact_w_note(**body_args).to_json} )
    puts "processed for #{fname} #{lname}: #{response}"
  end

  def token
    ENV.fetch("KF_LIVE_TOKEN")
  end

  def headers
    { 
      "Content-Type": "application/json",
      "Authorization": "Token token=\"#{token}\""
    }
  end

  def contact(fname:, lname:, email:)
    {
      "data_format": "contact",
      "action_type": "update",
      "data_type": "json",
      "match_by": {
        "contact": "first_name_last_name_email",
        "group": "name"
      },
      "groups": ["W4W: Zeeland"],
      "data": [
        {
          "first_name": fname,
          "last_name": lname,
          "email": email,
          "W4W: Zeeland": "yes"
        }
      ]
    }
  end

  def contact_w_note(fname:, lname:, email:, note_time:, note_subject:)
    {
      "data_format": "contact_with_note",
      "action_type": "update",
      "data_type": "json",
      "match_by": {
        "contact": "first_name_last_name_email",
        "campaign": "name",
        "fund": "name",
        "group": "name"
      },
      "groups": ["W4W: Zeeland"],
      "data": [
        {
          "first_name": fname,
          "last_name": lname,
          "email": email,
          "note_time": note_time,
          "note_subject": note_subject,
          "note_type": "Event",
          "campaign": "Social Fundraisers",
          "fund": "Special Events 40400",
          "W4W: Zeeland": "yes"
        }
      ]
    }
  end

end