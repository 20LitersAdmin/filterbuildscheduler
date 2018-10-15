# frozen_string_literal: true

class ImportClient
  include HTTParty

  ###### How to manually batch-enter people into Kindful using this app:
  # Recommendation: Test in sandbox first, always. Switch string on lines 19. This is a dummy check, Dummy.
  # Add data to import_data.txt, can include: { fname, lname, email, optional: [groups, note_subject, note_type, message_body, note_sender_name, note_sender_email, campaign, fund] }
  # Adjust the string and time values in this file, if fields are coming from import_data.txt, be sure to change strings to variables and add variable calls to methods and line 16
  # Change line 16 below if necessary. Options are: [.import_user(), .import_user_w_note(), .import_user_w_note_and_group()] 

  # in Rails Console (be sure file is saved and pristine before loading):
  # require "import_client"
  # users = eval(File.read(Rails.root.to_s + '/app/services/import_data.txt'))
  # ic = ImportClient.new
  # ic.dummy # checks env && base_uri
  # users.each do |user|
  #   ic.import_user_w_note(user[:fname], user[:lname], user[:email], user[:subject], user[:msg])
  # end

  DUMMY = 'test' # change this to 'live' when ready.

  if DUMMY == 'live'
    base_uri 'https://app.kindful.com/api/v1'
  else
    base_uri 'https://app-sandbox.kindful.com/api/v1'
  end

  # https://developer.kindful.com/reference
  def import_user(fname, lname, email)
    body_args = {
      fname: fname,
      lname: lname,
      email: email
    }
    response = self.class.post('/imports', { headers: headers, body: contact(**body_args).to_json })
    puts "processed for #{fname} #{lname}: #{response}"
  end

  # https://developer.kindful.com/reference#contact_with_note
  def import_user_w_note(fname, lname, email, subject, msg)
    case msg
    when 1
      message = MSG1
    when 2
      message = MSG2
    when 3
      message = MSG3
    end

    body_args = {
      fname: fname,
      lname: lname,
      email: email,
      note_time: Time.new(2018, 10, 04, 9, 30, 00).utc,
      note_subject: subject,
      note_type: 'Received Email',
      message_body: message,
      note_sender_name: 'Amanda',
      note_sender_email: 'amanda@20liters.org',
      campaign: 'Contributions',
      fund: 'Contributions 40100'
    }
    response = self.class.post('/imports', { headers: headers, body: contact_w_note(**body_args).to_json })
    puts "processed for #{fname} #{lname}: #{response}"
  end

  # https://developer.kindful.com/reference#contact_with_note
  def import_user_w_note_and_group(fname, lname, email)
    body_args = {
      fname: fname,
      lname: lname,
      email: email,
      note_time: Time.new(2018, 9, 28, 9).iso8601,
      note_subject: 'MOU Preview',
      note_type: 'Call',
      note_body: '',
      note_sender_name: '',
      note_sender_email: '',
      campaign: 'Contributions',
      fund: 'Contributions 40100',
      groups: ['Group name', 'Another group']
    }
    response = self.class.post('/imports', { headers: headers, body: contact_w_note_and_groups(**body_args).to_json })
    puts "processed for #{fname} #{lname}: #{response}"
  end

  def contact(fname:, lname:, email:)
    {
      "data_format": 'contact',
      "action_type": 'update',
      "data_type": 'json',
      "match_by": {
        "contact": 'first_name_last_name_email'
      },
      "data": [
        {
          "first_name": fname,
          "last_name": lname,
          "email": email
        }
      ]
    }
  end

  def contact_w_note(fname:, lname:, email:, note_time:, note_subject:, note_type:, message_body:, note_sender_name:, note_sender_email:, campaign:, fund:)
    {
      "data_format": 'contact_with_note',
      "action_type": 'update',
      "data_type": 'json',
      "match_by": {
        "contact": 'first_name_last_name_email',
        "campaign": 'name',
        "fund": 'name'
      },
      "data": [
        {
          "first_name": fname,
          "last_name": lname,
          "email": email,
          "note_time": note_time,
          "note_subject": note_subject,
          "note_type": note_type,
          "message_body": message_body,
          "note_sender_name": note_sender_name,
          "note_sender_email": note_sender_email,
          "campaign": campaign,
          "fund": fund,
        }
      ]
    }
  end

  def contact_w_note_and_groups(fname:, lname:, email:, note_time:, note_subject:, note_type:, groups:, campaign:, fund:)
    hash = {
      "data_format": 'contact_with_note',
      "action_type": 'update',
      "data_type": 'json',
      "match_by": {
        "contact": 'first_name_last_name_email',
        "campaign": 'name',
        "fund": 'name',
        "group": 'name'
      },
      "groups": groups,
      "data": [
        {
          "first_name": fname,
          "last_name": lname,
          "email": email,
          "note_time": note_time,
          "note_subject": note_subject,
          "note_type": note_type,
          "campaign": campaign,
          "fund": fund
        }
      ]
    }

    groups.each do |group|
      hash[:data][0][group] = 'yes'
    end

    hash
  end

  def token
    if DUMMY == 'live'
      ENV.fetch('KF_LIVE_TOKEN')
    else
      ENV.fetch('KF_TEST_TOKEN')
    end
  end

  def headers
    {
      "Content-Type": 'application/json',
      "Authorization": "Token token=\"#{token}\""
    }
  end

  def dummy
    puts DUMMY + "; base_uri: " + self.class.base_uri
  end
end
