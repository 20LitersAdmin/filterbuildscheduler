# frozen_string_literal: true

class KindfulClient
  include HTTParty
  attr_accessor :results, :env

  def initialize(env: Rails.env.production? ? 'production' : 'sandbox')
    @query_token = ''
    @results = []
    # you can test in the sandbox by first setting @env to anything other than 'production'

    @env = env

    # easy way to change which campaign and fund are linked for body methods
    # NOTE: If Kindful is still changing the names of campaigns on import, try match_by: { campaign: 'name' }
    # and remove campaign_id and fund_id and fund_name values
    @kindful_email = {
      campaign_id: '247247',
      campaign_name: 'Contributions',
      fund_id: '25946',
      fund_name: 'Contributions 40100'
    }

    @kindful_filter_build = {
      campaign_id: '338482',
      campaign_name: 'Filter Builds',
      fund_id: '25946',
      fund_name: 'Contributions 40100'
    }

    @kindful_causevox = {
      campaign_id: '270572',
      campaign_name: 'CauseVox Transactions',
      fund_id: '27452',
      fund_name: 'Special Events 40400'
    }

    set_host
  end

  def set_host
    @host = @env == 'production' ? 'https://app.kindful.com/api/v1/' : 'https://app-sandbox.kindful.com/api/v1'
  end

  def self.post(url, opts)
    # superceeds to HTTParty.post
    # don't actually send test data
    super(url, opts) unless Rails.env.test?
  end

  # action methods:

  def import_transaction(transaction)
    # used by WebhooksController#stripe, which calls this method if the stripe data is for a CauseVox transaction
    set_host
    self.class.post(import_host, { headers: headers, body: contact_w_transaction(transaction) })
  end

  def import_user(user)
    # used by User#update_kindful, which fires on after_save when contact fields have changed
    set_host
    self.class.post(import_host, { headers: headers, body: contact(user) })
  end

  def import_company_w_email_note(email_address, email, direction, company_name)
    # used by Email#send_to_kindful, when the email_address matches to an organization record
    set_host
    self.class.post(import_host, { headers: headers, body: company_w_email_note(email_address, email, direction, company_name) })
  end

  def import_user_w_email_note(email_address, email, direction)
    # used by Email#send_to_kindful, when the email_address does not match to an organization record
    set_host
    self.class.post(import_host, { headers: headers, body: contact_w_email_note(email_address, email, direction) })
  end

  def import_user_w_note(registration)
    # used by EventsController#update, when event report is submitted, all event.registrations.attended records call this
    set_host
    self.class.post(import_host, { headers: headers, body: contact_w_note(registration) })
  end

  def email_exists_in_kindful?(email)
    # This method is always hitting the Production site with Production credentials
    response = self.class.get(email_host(email), { headers: live_headers })

    response.parsed_response['exist']
  end

  def query_organizations
    # queries Kindful's API to get a list of companies
    set_host
    response = self.class.post(query_host, { headers: headers, body: organizations_query })

    @results << response.parsed_response['results'] if response.parsed_response['results'].any?

    return unless response.parsed_response['has_more']

    @query_token = response.parsed_response['query_token']

    while response.parsed_response['has_more']
      response = self.class.post("#{query_host}?query_token=#{@query_token}", { headers: headers })
      @results << response.parsed_response['results'] if response.parsed_response['results'].any?
    end

    recreate_organizations
  end

  ### body methods:

  def contact(user)
    # create or update contact in Kindful
    # from import_user
    # add to 'Vol: Filter Builder group'
    group_name = 'Vol: Filter Builder'

    {
      data_format: 'contact',
      action_type: 'update',
      data_type: 'json',
      match_by: {
        contact: 'first_name_last_name_email',
        group: 'name'
      },
      groups: [group_name],
      data: [
        {
          id: user.id.to_s,
          first_name: user.fname,
          last_name: user.lname,
          email: user.email,
          primary_phone: user.phone,
          email_opt_in: user.email_opt_in,
          country: 'US',
          group_name => 'yes'
        }
      ]
    }.to_json
  end

  def company_w_email_note(email_address, email, direction, company_name)
    # used by EmailSyncJob
    # create or update company
    # add email as note record linked to company
    # direction: 'Received Email' || 'Sent Email'
    {
      data_format: 'contact_with_note',
      action_type: 'update',
      data_type: 'json',
      match_by: {
        contact: 'company_name_email',
        campaign: 'id',
        fund: 'id'
      },
      data: [
        {
          id: email.id.to_s,
          company_name: company_name,
          email: email_address,
          country: 'US',
          note_id: email.message_id.to_s,
          note_time: email.datetime,
          note_subject: email.subject,
          note_body: email.body,
          message_body: email.snippet,
          note_type: direction,
          note_sender_name: email.oauth_user.name,
          note_sender_email: email.oauth_user.email,
          campaign_id: @kindful_email[:campaign_id],
          campaign_name: @kindful_email[:campaign_name],
          fund_id: @kindful_email[:fund_id],
          fund_name: @kindful_email[:fund_name]
        }
      ]
    }.to_json
  end

  def contact_w_email_note(email_address, email, direction)
    # used by EmailSyncJob
    # create or update contact
    # add email as note record linked to contact
    # direction: 'Received Email' || 'Sent Email'
    {
      data_format: 'contact_with_note',
      action_type: 'update',
      data_type: 'json',
      match_by: {
        contact: 'email',
        campaign: 'id',
        fund: 'id'
      },
      data: [
        {
          id: email.id.to_s,
          email: email_address,
          country: 'US',
          note_id: email.message_id.to_s,
          note_time: email.datetime,
          note_subject: email.subject,
          note_body: email.body,
          message_body: email.snippet,
          note_type: direction,
          note_sender_name: email.oauth_user.name,
          note_sender_email: email.oauth_user.email,
          campaign_id: @kindful_email[:campaign_id],
          campaign_name: @kindful_email[:campaign_name],
          fund_id: @kindful_email[:fund_id],
          fund_name: @kindful_email[:fund_name]
        }
      ]
    }.to_json
  end

  def contact_w_note(registration)
    # from import_user_w_note(registration)
    # create or update contact
    # adds a note about filter build event attendance

    role = registration.leader? ? 'Leader:' : 'Builder:'

    guests = registration.guests_attended.positive? ? "(#{registration.guests_attended} #{'guest'.pluralize(registration.guests_attended)})" : ''

    subject = "[Filter Build] #{role} #{registration.event.title} #{guests}"

    {
      data_format: 'contact_with_note',
      action_type: 'update',
      data_type: 'json',
      match_by: {
        contact: 'first_name_last_name_email',
        campaign: 'id',
        fund: 'id'
      },
      data: [
        {
          id: registration.user.id.to_s,
          first_name: registration.user.fname,
          last_name: registration.user.lname,
          email: registration.user.email,
          primary_phone: registration.user.phone,
          email_opt_in: registration.user.email_opt_in,
          country: 'US',
          note_id: registration.id.to_s,
          note_time: registration.event.end_time.to_s,
          note_subject: subject,
          note_type: 'Event',
          campaign_id: @kindful_filter_build[:campaign_id],
          campaign_name: @kindful_filter_build[:campaign_name],
          fund_id: @kindful_filter_build[:fund_id],
          fund_name: @kindful_filter_build[:fund_name]
        }
      ]
    }.to_json
  end

  def contact_w_transaction(opts)
    # from import_transaction
    # creates or updates a contact
    # creates a transaction (CauseVox transaction)
    {
      data_format: 'contact_with_transaction',
      action_type: 'create',
      data_type: 'json',
      match_by: {
        contact: 'first_name_last_name_email',
        campaign: 'id',
        fund: 'id'
      },
      data: [
        {
          first_name: opts[:metadata][:first_name],
          last_name: opts[:metadata][:last_name],
          email: opts[:metadata][:email],
          addr1: opts[:metadata][:line1],
          addr2: opts[:metadata][:line2],
          city: opts[:metadata][:city],
          state: opts[:metadata][:state],
          postal: opts[:metadata][:zipcode],
          country: opts[:metadata][:country],
          amount_in_cents: opts[:amount],
          currency: 'usd',
          transaction_time: opts[:created],
          acknowledged: 'false',
          transaction_note: opts[:metadata][:campaign_name],
          stripe_charge_id: opts[:id],
          transaction_type: opts[:source][:funding],
          card_type: opts[:source][:brand],
          campaign_id: @kindful_causevox[:campaign_id],
          campaign_name: @kindful_causevox[:campaign_name],
          fund_id: @kindful_causevox[:fund_id],
          fund_name: @kindful_causevox[:fund_name]
         }
      ]
    }.to_json
  end

  def organizations_query
    # from query_organizations
    # returns a collection of organizations with emails
    {
      query:
        [
          {
            or:
              [
                { by_group_id: '22330' },
                { by_group_id: '28657' },
                { by_group_id: '28658' },
                { by_group_id: '17846' }
              ]
          },
          { has_email: 'Yes' }
        ],
      columns: { contact: %w[company_name email donor_type] }
    }.to_json
  end

  def import_host
    # endpoint for importing data
    "#{@host}/imports"
  end

  def email_host(email)
    # endpoint for checking if an email exists in Kindful
    "https://app.kindful.com/api/v1/contacts/email_exist?email=#{email}"
  end

  def query_host
    # endpoint for querying data
    "#{@host}/contacts/query"
  end

  private

  def recreate_organizations
    return unless @results.any?

    Organization.delete_all

    @results.flatten.each do |result|
      next if result['donor_type'] != 'Organization' && (result['email'].blank? || result['company_name'].blank?)

      Organization.create(company_name: result['company_name'], email: result['email'])
    end
  end

  def token
    if @env == 'production'
      Rails.application.credentials.kf_filterbuild_token
    else
      Rails.application.credentials.kf_filterbuild_token_sandbox
    end
  end

  def headers
    {
      'Content-Type': 'application/json',
      'Authorization': 'Token token="' + token + '"'
    }
  end

  def live_headers
    {
      'Content-Type': 'application/json',
      'Authorization': 'Token token="' + Rails.application.credentials.kf_filterbuild_token + '"'
    }
  end
end
