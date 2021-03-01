# frozen_string_literal: true

class KindfulClient
  include HTTParty

  def initialize
    @results = []
    @page_token = ''
  end

  def org_results
    @results
  end

  if Rails.env.production? || Rails.env.development?
    base_uri 'https://app.kindful.com/api/v1'
  else
    base_uri 'https://app-sandbox.kindful.com/api/v1'
  end

  def self.post(url, opts)
    # superceeds to HTTParty.post
    # don't actually send test data
    super(url, opts) unless Rails.env.test?
  end

  def headers
    {
      'Content-Type': 'application/json',
      'Authorization': 'Token token="' + token + '"'
    }
  end

  def import_transaction(transaction)
    self.class.post('/imports', { headers: headers, body: contact_w_transaction(transaction) })
  end

  def import_user(user)
    self.class.post('/imports', { headers: headers, body: contact(user) })
  end

  def import_user_w_email_note(email_address, email, direction)
    self.class.post('/imports', { headers: headers, body: contact_w_email_note(email_address, email, direction) })
  end

  def import_user_w_note(registration)
    self.class.post('/imports', { headers: headers, body: contact_w_note(registration) })
  end

  def email_exists_in_kindful?(email)
    # This method is always hitting the Production site with Production credentials
    response = self.class.get("https://app.kindful.com/api/v1/contacts/email_exist?email=#{email}", { headers: live_headers })

    response.parsed_response['exist']
  end

  def query_organizations
    response = self.class.post('/contacts/query', { headers: headers, body: organizations_query })

    @results << response.parsed_response['results'] if response.parsed_response['results'].any?

    # TODO: strange loop method activation:
    # query_organizations_next(parsed_response.parsed_response['query_token']) if response.parsed_response['has_more']
  end

  def query_organizations_next(query_token)
    # TODO: does this work??
    while response.parsed_response['has_more']
      response = self.class.post('/contacts/query', { headers: headers, body: organizations_next_page(query_token) })
      @results << response.parsed_response['results'] if response.parsed_response['results'].any?
    end

    @results
  end

  # body methods

  def contact(user)
    {
      'data_format': 'contact',
      'action_type': 'update',
      'data_type': 'json',
      'match_by': {
        'contact': 'first_name_last_name_email',
        'group': 'name'
      },
      'groups': ['Vol: Filter Builder'],
      'data': [
        {
          'id': user.id.to_s,
          'first_name': user.fname,
          'last_name': user.lname,
          'email': user.email,
          'primary_phone': user.phone,
          'email_opt_in': user.email_opt_in,
          'country': 'US',
          'Volunteer: Filter Builders': 'yes'
        }
      ]
    }.to_json
  end

  def contact_w_email_note(email_address, email, direction)
    # direction: 'Received Email' || 'Sent Email'
    {
      'data_format': 'contact_with_note',
      'action_type': 'update',
      'data_type': 'json',
      'match_by': {
        'contact': 'email'
      },
        'data': [
          {
            'id': email.id.to_s,
            'email': email_address,
            'country': 'US',
            'note_id': email.message_id.to_s,
            'note_time': email.datetime,
            'note_subject': email.subject,
            'note_body': email.body,
            'message_body': email.snippet,
            'note_type': direction,
            'note_sender_name': email.oauth_user.name,
            'note_sender_email': email.oauth_user.email,
            'campaign': 'Contributions',
            'fund': 'Contributions 40100'
          }
        ]
      }.to_json
  end

  def contact_w_note(registration)
    role = registration.leader? ? 'Leader:' : 'Builder:'

    guests = registration.guests_attended.positive? ? "(#{registration.guests_attended} #{'guest'.pluralize(registration.guests_attended)})" : ''

    subject = "[Filter Build] #{role} #{registration.event.title} #{guests}"

    {
      'data_format': 'contact_with_note',
      'action_type': 'update',
      'data_type': 'json',
      'match_by': {
        'contact': 'first_name_last_name_email',
        'campaign': 'name',
        'fund': 'name'
      },
      'data': [
        {
          'id': registration.user.id.to_s,
          'first_name': registration.user.fname,
          'last_name': registration.user.lname,
          'email': registration.user.email,
          'primary_phone': registration.user.phone,
          'email_opt_in': registration.user.email_opt_in,
          'country': 'US',
          'note_id': registration.id.to_s,
          'note_time': registration.event.end_time.to_s,
          'note_subject': subject,
          'note_type': 'Event',
          'campaign': 'Filter Builds',
          'fund': 'Contributions 40100'
        }
      ]
    }.to_json
  end

  def contact_w_transaction(opts)
    {
      'data_format': 'contact_with_transaction',
      'action_type': 'create',
      'data_type': 'json',
      'match_by': {
        'contact': 'first_name_last_name_email',
        'campaign': 'name',
        'fund': 'name'
      },
      'data': [
        {
          'first_name': opts[:metadata][:first_name],
          'last_name': opts[:metadata][:last_name],
          'email': opts[:metadata][:email],
          'addr1': opts[:metadata][:line1],
          'addr2': opts[:metadata][:line2],
          'city': opts[:metadata][:city],
          'state': opts[:metadata][:state],
          'postal': opts[:metadata][:zipcode],
          'country': opts[:metadata][:country],
          'amount_in_cents': opts[:amount],
          'currency': 'usd',
          'campaign': 'CauseVox Transactions',
          'fund': 'Special Events 40400',
          'acknowledged': 'false',
          'transaction_note': opts[:metadata][:campaign_name],
          'stripe_charge_id': opts[:id],
          'transaction_type': 'Credit',
          'card_type': opts[:source][:brand]
         }
      ]
    }.to_json
  end

  def organizations_query
    {
      'query':
        [
          { 'or':
            [
              { 'by_group_id': '22330' },
              { 'by_group_id': '28657' },
              { 'by_group_id': '28658' },
              { 'by_group_id': '17846' }
            ] },
          { 'has_email': 'Yes' }
        ],
      'columns': { 'contact': %w[company_name email donor_type] }
    }.to_json
  end

  def organizations_next_page(query_token)
    # even sending the query_token appears unnecessary
    {
      "query_token": query_token
    }
  end

  private

  def token
    if Rails.env.production? || Rails.env.development?
      Rails.application.credentials.kf_filterbuild_token
    else
      Rails.application.credentials.kf_filterbuild_token_sandbox
    end
  end

  def live_headers
    {
      'Content-Type': 'application/json',
      'Authorization': 'Token token="' + Rails.application.credentials.kf_filterbuild_token + '"'
    }
  end
end
