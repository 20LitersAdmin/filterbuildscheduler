# frozen_string_literal: true

class ImportClient
  include HTTParty

  # base_uri "https://app-sandbox.kindful.com/api/v1"
  base_uri 'https://app.kindful.com/api/v1'

  ###### How to manually batch enter people into Kindful using this app:
  # Create a json file with fname, lname, email
  # Adjust the fields in this file (then save file before loading IRB):
  # - note_subject
  # - groups
  # - Lines 70 && 98
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
    self.class.post('/imports', { headers: headers, body: contact(**body_args).to_json })
    puts "processed for #{fname} #{lname}: #{response}"
  end

  def import_user_w_note(fname, lname, email)
    body_args = {
      fname: fname,
      lname: lname,
      email: email,
      note_time: Time.new(2018, 7, 14, 9).iso8601,
      note_subject: 'Attended Mars Hill Celebration 2018'
    }
    response = self.class.post('/imports', { headers: headers, body: contact_w_note(**body_args).to_json })
    puts "processed for #{fname} #{lname}: #{response}"
  end

  def token
    ENV.fetch('KF_LIVE_TOKEN')
  end

  def headers
    {
      "Content-Type": 'application/json',
      "Authorization": "Token token=\"#{token}\""
    }
  end

  def contact(fname:, lname:, email:)
    {
      "data_format": 'contact',
      "action_type": 'update',
      "data_type": 'json',
      "match_by": {
        "contact": 'first_name_last_name_email',
        "group": 'name'
      },
      "groups": ['Mars Hill Celebration 2018'],
      "data": [
        {
          "first_name": fname,
          "last_name": lname,
          "email": email,
          "Mars Hill Celebration 2018": 'yes'
        }
      ]
    }
  end

  def contact_w_note(fname:, lname:, email:, note_time:, note_subject:)
    {
      "data_format": 'contact_with_note',
      "action_type": 'update',
      "data_type": 'json',
      "match_by": {
        "contact": 'first_name_last_name_email',
        "campaign": 'name',
        "fund": 'name',
        "group": 'name'
      },
      "groups": ['Mars Hill Celebration 2018'],
      "data": [
        {
          "first_name": fname,
          "last_name": lname,
          "email": email,
          "note_time": note_time,
          "note_subject": note_subject,
          "note_type": 'Event',
          "campaign": 'Social Fundraisers',
          "fund": 'Special Events 40400',
          "Mars Hill Celebration 2018": 'yes'
        }
      ]
    }
  end
end
